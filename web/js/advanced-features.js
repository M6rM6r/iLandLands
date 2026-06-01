/**
 * Gulf Lands Market - Advanced JavaScript Features
 * Modern ES6+ JavaScript for enhanced user experience
 */

class GulfLandsAdvanced {
    constructor() {
        this.init();
        this.setupEventListeners();
        this.initializeAdvancedFeatures();
    }

    init() {
        console.log('🏗️ Gulf Lands Market - Advanced Features Initialized');
        
        // Initialize state management
        this.state = {
            currentView: 'grid',
            filters: {
                country: null,
                priceRange: null,
                areaRange: null,
                featured: false
            },
            userPreferences: {
                theme: 'auto',
                language: 'en',
                currency: 'SAR'
            },
            analytics: {
                pageViews: 0,
                timeSpent: 0,
                interactions: []
            }
        };

        // Initialize performance monitoring
        this.performanceMonitor = new PerformanceMonitor();
        
        // Initialize analytics
        this.analytics = new AdvancedAnalytics();
        
        // Initialize AI recommendations
        this.recommendationEngine = new AIRecommendationEngine();
        
        // Initialize progressive web app features
        this.pwaManager = new PWAManager();
        
        // Initialize offline capabilities
        this.offlineManager = new OfflineManager();
    }

    setupEventListeners() {
        // Performance monitoring
        this.performanceMonitor.startMonitoring();
        
        // Page visibility tracking
        document.addEventListener('visibilitychange', () => {
            this.handleVisibilityChange();
        });

        // Network status monitoring
        window.addEventListener('online', () => this.handleNetworkChange('online'));
        window.addEventListener('offline', () => this.handleNetworkChange('offline'));

        // Scroll-based lazy loading
        window.addEventListener('scroll', this.throttle(() => {
            this.handleScroll();
        }, 100));

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            this.handleKeyboardShortcuts(e);
        });

        // Touch gestures for mobile
        this.setupTouchGestures();

        // Web Share API
        if (navigator.share) {
            this.setupWebShare();
        }
    }

    initializeAdvancedFeatures() {
        // Initialize Web Components
        this.initializeWebComponents();
        
        // Initialize Service Worker
        this.initializeServiceWorker();
        
        // Initialize IndexedDB for offline storage
        this.initializeIndexedDB();
        
        // Initialize WebSockets for real-time updates
        this.initializeWebSockets();
        
        // Initialize Web Workers for heavy computations
        this.initializeWebWorkers();
        
        // Initialize Intersection Observer for animations
        this.initializeIntersectionObserver();
        
        // Initialize Resize Observer for responsive components
        this.initializeResizeObserver();
        
        // Initialize Mutation Observer for dynamic content
        this.initializeMutationObserver();
    }

    // Advanced Search with AI-powered suggestions
    initializeAdvancedSearch() {
        const searchInput = document.querySelector('#advanced-search');
        if (!searchInput) return;

        let searchTimeout;
        searchInput.addEventListener('input', (e) => {
            clearTimeout(searchTimeout);
            searchTimeout = setTimeout(() => {
                this.handleSearchInput(e.target.value);
            }, 300);
        });

        // Voice search support
        if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
            this.initializeVoiceSearch(searchInput);
        }
    }

    async handleSearchInput(query) {
        if (query.length < 2) {
            this.hideSearchSuggestions();
            return;
        }

        try {
            // Get AI-powered suggestions
            const suggestions = await this.recommendationEngine.getSearchSuggestions(query);
            this.displaySearchSuggestions(suggestions);
            
            // Track search analytics
            this.analytics.trackEvent('search', {
                query: query,
                suggestions_count: suggestions.length,
                timestamp: Date.now()
            });
        } catch (error) {
            console.error('Search error:', error);
        }
    }

    // AI-powered recommendations
    async loadRecommendations(userId) {
        try {
            const recommendations = await this.recommendationEngine.getPersonalizedRecommendations(userId);
            this.displayRecommendations(recommendations);
            
            // Track recommendation analytics
            this.analytics.trackEvent('recommendations_loaded', {
                user_id: userId,
                count: recommendations.length,
                algorithm: 'hybrid'
            });
        } catch (error) {
            console.error('Recommendations error:', error);
        }
    }

    // Progressive Web App features
    initializeServiceWorker() {
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('/sw.js')
                .then(registration => {
                    console.log('✅ Service Worker registered:', registration);
                    
                    // Check for updates
                    registration.addEventListener('updatefound', () => {
                        const newWorker = registration.installing;
                        newWorker.addEventListener('statechange', () => {
                            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                                this.showUpdateAvailable();
                            }
                        });
                    });
                })
                .catch(error => {
                    console.error('❌ Service Worker registration failed:', error);
                });
        }
    }

    // IndexedDB for offline storage
    async initializeIndexedDB() {
        try {
            this.db = await this.openIndexedDB();
            console.log('✅ IndexedDB initialized');
            
            // Sync offline data
            await this.syncOfflineData();
        } catch (error) {
            console.error('❌ IndexedDB initialization failed:', error);
        }
    }

    openIndexedDB() {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open('GulfLandsDB', 1);
            
            request.onerror = () => reject(request.error);
            request.onsuccess = () => resolve(request.result);
            
            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                
                // Create object stores
                if (!db.objectStoreNames.contains('listings')) {
                    const listingsStore = db.createObjectStore('listings', { keyPath: 'id' });
                    listingsStore.createIndex('country', 'country', { unique: false });
                    listingsStore.createIndex('price', 'price', { unique: false });
                    listingsStore.createIndex('created_at', 'created_at', { unique: false });
                }
                
                if (!db.objectStoreNames.contains('favorites')) {
                    db.createObjectStore('favorites', { keyPath: 'id' });
                }
                
                if (!db.objectStoreNames.contains('search_history')) {
                    db.createObjectStore('search_history', { keyPath: 'id', autoIncrement: true });
                }
            };
        });
    }

    // WebSockets for real-time updates
    initializeWebSockets() {
        const wsUrl = `wss://${window.location.host}/ws`;
        
        try {
            this.ws = new WebSocket(wsUrl);
            
            this.ws.onopen = () => {
                console.log('✅ WebSocket connected');
                this.ws.send(JSON.stringify({ type: 'subscribe', channel: 'listings' }));
            };
            
            this.ws.onmessage = (event) => {
                const data = JSON.parse(event.data);
                this.handleWebSocketMessage(data);
            };
            
            this.ws.onclose = () => {
                console.log('❌ WebSocket disconnected');
                // Attempt to reconnect after 5 seconds
                setTimeout(() => this.initializeWebSockets(), 5000);
            };
            
            this.ws.onerror = (error) => {
                console.error('❌ WebSocket error:', error);
            };
        } catch (error) {
            console.error('❌ WebSocket initialization failed:', error);
        }
    }

    handleWebSocketMessage(data) {
        switch (data.type) {
            case 'listing_update':
                this.updateListing(data.payload);
                break;
            case 'price_change':
                this.notifyPriceChange(data.payload);
                break;
            case 'new_listing':
                this.addNewListing(data.payload);
                break;
            case 'user_activity':
                this.updateUserActivity(data.payload);
                break;
        }
    }

    // Web Workers for heavy computations
    initializeWebWorkers() {
        // Create worker for price calculations
        this.priceWorker = new Worker('/js/workers/price-calculator.js');
        
        this.priceWorker.onmessage = (e) => {
            this.handlePriceCalculation(e.data);
        };
        
        // Create worker for recommendation calculations
        this.recommendationWorker = new Worker('/js/workers/recommendation-calculator.js');
        
        this.recommendationWorker.onmessage = (e) => {
            this.handleRecommendationCalculation(e.data);
        };
    }

    // Intersection Observer for animations
    initializeIntersectionObserver() {
        const options = {
            root: null,
            rootMargin: '0px',
            threshold: [0.1, 0.5, 1.0]
        };
        
        this.intersectionObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateElement(entry.target);
                }
            });
        }, options);
        
        // Observe all cards
        document.querySelectorAll('.land-plot-card').forEach(card => {
            this.intersectionObserver.observe(card);
        });
    }

    // Resize Observer for responsive components
    initializeResizeObserver() {
        this.resizeObserver = new ResizeObserver((entries) => {
            entries.forEach(entry => {
                this.handleResize(entry.target, entry.contentRect);
            });
        });
        
        // Observe grid container
        const gridContainer = document.querySelector('.listings-grid');
        if (gridContainer) {
            this.resizeObserver.observe(gridContainer);
        }
    }

    // Mutation Observer for dynamic content
    initializeMutationObserver() {
        this.mutationObserver = new MutationObserver((mutations) => {
            mutations.forEach(mutation => {
                if (mutation.type === 'childList') {
                    mutation.addedNodes.forEach(node => {
                        if (node.nodeType === Node.ELEMENT_NODE) {
                            this.handleNewElement(node);
                        }
                    });
                }
            });
        });
        
        // Observe listings container
        const container = document.querySelector('.listings-container');
        if (container) {
            this.mutationObserver.observe(container, {
                childList: true,
                subtree: true
            });
        }
    }

    // Advanced filtering with debouncing
    setupAdvancedFilters() {
        const filterElements = document.querySelectorAll('.filter-control');
        
        filterElements.forEach(element => {
            element.addEventListener('change', this.debounce((e) => {
                this.applyFilters(e.target);
            }, 300));
        });
    }

    // Virtual scrolling for large datasets
    initializeVirtualScroll() {
        const container = document.querySelector('.virtual-scroll-container');
        if (!container) return;
        
        this.virtualScroll = new VirtualScroll({
            container: container,
            itemHeight: 300,
            renderItem: (item, index) => this.renderListingItem(item, index),
            loadMore: (offset, limit) => this.loadMoreListings(offset, limit)
        });
    }

    // Image lazy loading with blur effect
    initializeLazyLoading() {
        const images = document.querySelectorAll('img[data-src]');
        
        if ('IntersectionObserver' in window) {
            const imageObserver = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        this.loadImage(entry.target);
                        imageObserver.unobserve(entry.target);
                    }
                });
            });
            
            images.forEach(img => imageObserver.observe(img));
        } else {
            // Fallback for older browsers
            images.forEach(img => this.loadImage(img));
        }
    }

    loadImage(img) {
        const src = img.dataset.src;
        if (!src) return;
        
        // Add blur effect during loading
        img.style.filter = 'blur(5px)';
        img.style.transition = 'filter 0.3s ease';
        
        img.onload = () => {
            img.style.filter = 'blur(0)';
            img.removeAttribute('data-src');
        };
        
        img.src = src;
    }

    // Utility functions
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }

    // Event handlers
    handleVisibilityChange() {
        if (document.hidden) {
            this.analytics.trackEvent('page_hidden');
            this.performanceMonitor.pauseTracking();
        } else {
            this.analytics.trackEvent('page_visible');
            this.performanceMonitor.resumeTracking();
        }
    }

    handleNetworkChange(status) {
        this.analytics.trackEvent('network_change', { status });
        
        if (status === 'online') {
            this.syncOfflineData();
            this.showNetworkStatus('online');
        } else {
            this.showNetworkStatus('offline');
        }
    }

    handleScroll() {
        // Infinite scroll
        const scrollPosition = window.innerHeight + window.scrollY;
        const documentHeight = document.documentElement.offsetHeight;
        
        if (scrollPosition >= documentHeight - 1000) {
            this.loadMoreListings();
        }
    }

    handleKeyboardShortcuts(e) {
        // Ctrl/Cmd + K for search
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            this.focusSearch();
        }
        
        // Escape to close modals
        if (e.key === 'Escape') {
            this.closeAllModals();
        }
        
        // Arrow keys for navigation
        if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
            this.handleArrowNavigation(e.key);
        }
    }

    // Touch gestures for mobile
    setupTouchGestures() {
        let touchStartX = 0;
        let touchStartY = 0;
        
        document.addEventListener('touchstart', (e) => {
            touchStartX = e.touches[0].clientX;
            touchStartY = e.touches[0].clientY;
        });
        
        document.addEventListener('touchend', (e) => {
            const touchEndX = e.changedTouches[0].clientX;
            const touchEndY = e.changedTouches[0].clientY;
            
            const deltaX = touchEndX - touchStartX;
            const deltaY = touchEndY - touchStartY;
            
            // Swipe detection
            if (Math.abs(deltaX) > Math.abs(deltaY) && Math.abs(deltaX) > 50) {
                this.handleSwipe(deltaX > 0 ? 'right' : 'left');
            }
        });
    }

    // Web Share API
    setupWebShare() {
        const shareButtons = document.querySelectorAll('[data-share]');
        
        shareButtons.forEach(button => {
            button.addEventListener('click', async (e) => {
                e.preventDefault();
                
                const data = JSON.parse(button.dataset.share);
                
                try {
                    await navigator.share(data);
                    this.analytics.trackEvent('share_success', data);
                } catch (error) {
                    console.log('Share cancelled or failed:', error);
                    this.analytics.trackEvent('share_cancelled', data);
                }
            });
        });
    }

    // Voice search
    initializeVoiceSearch(searchInput) {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        const recognition = new SpeechRecognition();
        
        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.lang = 'en-US';
        
        const voiceButton = document.querySelector('#voice-search-btn');
        if (voiceButton) {
            voiceButton.addEventListener('click', () => {
                recognition.start();
                voiceButton.classList.add('listening');
            });
        }
        
        recognition.onresult = (event) => {
            const transcript = event.results[0][0].transcript;
            searchInput.value = transcript;
            this.handleSearchInput(transcript);
            
            if (voiceButton) {
                voiceButton.classList.remove('listening');
            }
        };
        
        recognition.onerror = (event) => {
            console.error('Speech recognition error:', event.error);
            if (voiceButton) {
                voiceButton.classList.remove('listening');
            }
        };
    }

    // Performance monitoring
    startPerformanceTracking() {
        // Track Core Web Vitals
        this.trackCoreWebVitals();
        
        // Track custom metrics
        this.trackCustomMetrics();
    }

    trackCoreWebVitals() {
        // Largest Contentful Paint (LCP)
        new PerformanceObserver((list) => {
            const entries = list.getEntries();
            const lastEntry = entries[entries.length - 1];
            this.analytics.trackMetric('lcp', lastEntry.startTime);
        }).observe({ entryTypes: ['largest-contentful-paint'] });

        // First Input Delay (FID)
        new PerformanceObserver((list) => {
            const entries = list.getEntries();
            entries.forEach(entry => {
                this.analytics.trackMetric('fid', entry.processingStart - entry.startTime);
            });
        }).observe({ entryTypes: ['first-input'] });

        // Cumulative Layout Shift (CLS)
        let clsValue = 0;
        new PerformanceObserver((list) => {
            const entries = list.getEntries();
            entries.forEach(entry => {
                if (!entry.hadRecentInput) {
                    clsValue += entry.value;
                    this.analytics.trackMetric('cls', clsValue);
                }
            });
        }).observe({ entryTypes: ['layout-shift'] });
    }

    // Initialize everything when DOM is ready
    static initialize() {
        document.addEventListener('DOMContentLoaded', () => {
            new GulfLandsAdvanced();
        });
    }
}

// Initialize the application
GulfLandsAdvanced.initialize();

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = GulfLandsAdvanced;
}
