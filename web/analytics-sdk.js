/**
 * Gulf Lands Analytics SDK
 * JavaScript SDK for tracking user interactions and events
 * Version 1.0.0
 */

(function(window) {
    'use strict';

    class AnalyticsSDK {
        constructor(config = {}) {
            this.endpoint = config.endpoint || '/v1/analytics/events';
            this.batchSize = config.batchSize || 10;
            this.maxRetries = config.maxRetries || 5;
            this.backoffMultiplier = config.backoffMultiplier || 2;
            this.initialBackoff = config.initialBackoff || 1000; // 1 second
            this.flushInterval = config.flushInterval || 30000; // 30 seconds

            this.queue = [];
            this.failedQueue = [];
            this.isSending = false;
            this.sessionId = this.generateSessionId();
            this.userId = this.generateUserId();

            this.loadPersistedData();
            this.startFlushTimer();
            this.setupVisibilityHandler();
        }

        /**
         * Generate a privacy-safe session ID
         */
        generateSessionId() {
            const timestamp = Date.now();
            const random = Math.random().toString(36).substr(2, 9);
            return this.hashString(`${timestamp}-${random}`);
        }

        /**
         * Generate a privacy-safe user ID using browser fingerprinting
         */
        generateUserId() {
            const fingerprint = [
                navigator.userAgent,
                navigator.language,
                screen.width + 'x' + screen.height,
                new Date().getTimezoneOffset()
            ].join('|');
            return this.hashString(fingerprint);
        }

        /**
         * Simple hash function for pseudonymization
         */
        hashString(str) {
            let hash = 0;
            for (let i = 0; i < str.length; i++) {
                const char = str.charCodeAt(i);
                hash = ((hash << 5) - hash) + char;
                hash = hash & hash; // Convert to 32-bit integer
            }
            return Math.abs(hash).toString(36);
        }

        /**
         * Load persisted data from localStorage
         */
        loadPersistedData() {
            try {
                const persisted = localStorage.getItem('gulflands_analytics_queue');
                if (persisted) {
                    this.queue = JSON.parse(persisted);
                }
                const failed = localStorage.getItem('gulflands_analytics_failed');
                if (failed) {
                    this.failedQueue = JSON.parse(failed);
                }
                // Retry failed events
                this.retryFailedEvents();
            } catch (e) {
                console.warn('Failed to load persisted analytics data:', e);
            }
        }

        /**
         * Persist queue to localStorage
         */
        persistQueue() {
            try {
                localStorage.setItem('gulflands_analytics_queue', JSON.stringify(this.queue));
            } catch (e) {
                console.warn('Failed to persist analytics queue:', e);
            }
        }

        /**
         * Persist failed queue to localStorage
         */
        persistFailedQueue() {
            try {
                localStorage.setItem('gulflands_analytics_failed', JSON.stringify(this.failedQueue));
            } catch (e) {
                console.warn('Failed to persist failed analytics queue:', e);
            }
        }

        /**
         * Start timer for periodic flushing
         */
        startFlushTimer() {
            setInterval(() => {
                this.flush();
            }, this.flushInterval);
        }

        /**
         * Handle page visibility changes to flush on unload
         */
        setupVisibilityHandler() {
            if (typeof document !== 'undefined') {
                document.addEventListener('visibilitychange', () => {
                    if (document.visibilityState === 'hidden') {
                        this.flush();
                    }
                });
                window.addEventListener('beforeunload', () => {
                    this.flush();
                });
            }
        }

        /**
         * Track a page view event
         */
        trackPageView(properties = {}) {
            this.track('page_view', {
                page: typeof window !== 'undefined' ? window.location.pathname : '',
                referrer: typeof document !== 'undefined' ? document.referrer : '',
                ...properties
            });
        }

        /**
         * Track filter applied event
         */
        trackFilterApplied(properties = {}) {
            this.track('filter_applied', properties);
        }

        /**
         * Track listing opened event
         */
        trackListingOpened(listingId, properties = {}) {
            this.track('listing_opened', {
                listing_id: listingId,
                ...properties
            });
        }

        /**
         * Track favorite toggled event
         */
        trackFavoriteToggled(listingId, favorited, properties = {}) {
            this.track('favorite_toggled', {
                listing_id: listingId,
                favorited: favorited,
                ...properties
            });
        }

        /**
         * Track contact clicked event
         */
        trackContactClicked(listingId, contactType, properties = {}) {
            this.track('contact_clicked', {
                listing_id: listingId,
                contact_type: contactType,
                ...properties
            });
        }

        /**
         * Generic track method
         */
        track(eventName, properties = {}) {
            const event = {
                event: eventName,
                properties: {
                    ...properties,
                    timestamp: new Date().toISOString(),
                    session_id: this.sessionId,
                    user_id: this.userId,
                    user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
                    url: typeof window !== 'undefined' ? window.location.href : ''
                }
            };

            this.queue.push(event);
            this.persistQueue();

            if (this.queue.length >= this.batchSize) {
                this.flush();
            }
        }

        /**
         * Flush the queue by sending batched events
         */
        async flush() {
            if (this.isSending || this.queue.length === 0) {
                return;
            }

            this.isSending = true;
            const batch = this.queue.splice(0, this.batchSize);
            this.persistQueue();

            try {
                await this.sendBatch(batch);
            } catch (error) {
                console.warn('Failed to send analytics batch:', error);
                this.failedQueue.push(...batch);
                this.persistFailedQueue();
            } finally {
                this.isSending = false;
            }
        }

        /**
         * Send a batch of events to the backend
         */
        async sendBatch(events) {
            const response = await fetch(this.endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ events }),
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const result = await response.json();
            return result;
        }

        /**
         * Retry failed events with exponential backoff
         */
        async retryFailedEvents() {
            if (this.failedQueue.length === 0) {
                return;
            }

            const events = [...this.failedQueue];
            this.failedQueue = [];
            this.persistFailedQueue();

            for (const event of events) {
                await this.sendWithRetry(event);
            }
        }

        /**
         * Send event with retry logic and exponential backoff
         */
        async sendWithRetry(event) {
            let delay = this.initialBackoff;

            for (let attempt = 0; attempt < this.maxRetries; attempt++) {
                try {
                    await this.sendBatch([event]);
                    return; // Success
                } catch (error) {
                    if (attempt === this.maxRetries - 1) {
                        // Final attempt failed, add back to failed queue
                        this.failedQueue.push(event);
                        this.persistFailedQueue();
                        console.warn('Event failed permanently after retries:', event, error);
                        return;
                    }

                    // Wait before retry
                    await this.delay(delay);
                    delay *= this.backoffMultiplier;
                }
            }
        }

        /**
         * Utility method for delays
         */
        delay(ms) {
            return new Promise(resolve => setTimeout(resolve, ms));
        }

        /**
         * Get current queue status (for debugging)
         */
        getStatus() {
            return {
                queueLength: this.queue.length,
                failedQueueLength: this.failedQueue.length,
                isSending: this.isSending,
                sessionId: this.sessionId,
                userId: this.userId
            };
        }
    }

    // Export for different environments
    if (typeof module !== 'undefined' && module.exports) {
        // Node.js
        module.exports = AnalyticsSDK;
    } else if (typeof define === 'function' && define.amd) {
        // AMD
        define([], function() {
            return AnalyticsSDK;
        });
    } else {
        // Browser global
        window.AnalyticsSDK = AnalyticsSDK;
    }

})(typeof window !== 'undefined' ? window : this);