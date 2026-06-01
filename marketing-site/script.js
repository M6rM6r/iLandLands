// Land Plot Data Validator
// Include land_plot_validator.js before this script

// Land Plot Data Validator
// Include land_plot_validator.js before this script

// Utility functions for security
const SecurityUtils = {
    // HTML encode to prevent XSS
    encodeHTML: function(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    },

    // Validate email format
    isValidEmail: function(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email) && email.length <= 254;
    },

    // Sanitize user input
    sanitizeInput: function(input) {
        if (typeof input !== 'string') return input;
        return input.replace(/[<>]/g, '').trim();
    },

    // Validate URL
    isValidUrl: function(url) {
        try {
            const parsedUrl = new URL(url);
            return ['http:', 'https:'].includes(parsedUrl.protocol);
        } catch {
            return false;
        }
    }
};

// Analytics tracking using Gulf Lands Analytics SDK
// Include analytics-sdk.js before this script

// Initialize analytics
const analytics = new AnalyticsSDK({
    endpoint: '/api/analytics/events', // Adjust based on your backend setup
    batchSize: 5,
    maxRetries: 3,
    flushInterval: 15000
});

// Track initial page view
analytics.trackPageView({
    page_title: document.title,
    referrer: document.referrer
});

// Track CTA clicks
document.querySelectorAll('.cta-button').forEach(button => {
    button.addEventListener('click', (e) => {
        analytics.trackContactClicked('marketing_cta', 'download_app', {
            button_text: e.target.textContent,
            button_location: e.target.closest('section')?.id || 'unknown'
        });
    });
});

// Track filter interactions (if filters exist on marketing site)
document.querySelectorAll('.filter-button')?.forEach(button => {
    button.addEventListener('click', (e) => {
        analytics.trackFilterApplied({
            filter_type: e.target.dataset.filterType,
            filter_value: e.target.dataset.filterValue
        });
    });
});

// Track listing card clicks
document.querySelectorAll('.listing-card')?.forEach(card => {
    card.addEventListener('click', (e) => {
        const listingId = card.dataset.listingId || 'unknown';
        analytics.trackListingOpened(listingId, {
            source: 'marketing_site',
            card_position: Array.from(card.parentNode.children).indexOf(card)
        });
    });
});

// Track favorite toggles (if implemented)
document.querySelectorAll('.favorite-btn')?.forEach(btn => {
    btn.addEventListener('click', (e) => {
        const listingId = btn.dataset.listingId || 'unknown';
        const isFavorited = btn.classList.contains('favorited');
        analytics.trackFavoriteToggled(listingId, !isFavorited, {
            source: 'marketing_site'
        });
    });
});

// Smooth scrolling for navigation
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start',
            });
        }
    });
});

// Intersection Observer for scroll animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px',
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('animate-in');
        }
    });
}, observerOptions);

// Observe elements for animation
document.querySelectorAll('.listing-card, .testimonial, .stat').forEach(el => {
    observer.observe(el);
});

// Performance monitoring
window.addEventListener('load', () => {
    const perfData = performance.getEntriesByType('navigation')[0];
    analytics.track('page_load', {
        dom_content_loaded: perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart,
        load_complete: perfData.loadEventEnd - perfData.loadEventStart,
        total_time: perfData.loadEventEnd - perfData.fetchStart,
    });
});

// Form validation and security
document.addEventListener('DOMContentLoaded', function() {
    const contactForm = document.querySelector('.contact-form');
    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault();

            const nameInput = contactForm.querySelector('input[type="text"]');
            const emailInput = contactForm.querySelector('input[type="email"]');
            const messageInput = contactForm.querySelector('textarea');

            // Validate inputs
            const name = SecurityUtils.sanitizeInput(nameInput.value);
            const email = emailInput.value.trim();
            const message = SecurityUtils.sanitizeInput(messageInput.value);

            // Clear previous errors
            clearFormErrors(contactForm);

            let hasErrors = false;

            // Validate name
            if (!name || name.length < 2 || name.length > 100) {
                showFieldError(nameInput, 'Name must be between 2 and 100 characters');
                hasErrors = true;
            }

            // Validate email
            if (!SecurityUtils.isValidEmail(email)) {
                showFieldError(emailInput, 'Please enter a valid email address');
                hasErrors = true;
            }

            // Validate message
            if (!message || message.length < 10 || message.length > 1000) {
                showFieldError(messageInput, 'Message must be between 10 and 1000 characters');
                hasErrors = true;
            }

            if (!hasErrors) {
                // Submit form securely
                submitContactForm({ name, email, message });
            }
        });
    }
});

function showFieldError(field, message) {
    field.classList.add('error');
    const errorDiv = document.createElement('div');
    errorDiv.className = 'field-error';
    errorDiv.textContent = message;
    field.parentNode.insertBefore(errorDiv, field.nextSibling);
}

function clearFormErrors(form) {
    form.querySelectorAll('.error').forEach(el => el.classList.remove('error'));
    form.querySelectorAll('.field-error').forEach(el => el.remove());
}

async function submitContactForm(data) {
    try {
        const response = await fetch('/api/contact', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });

        if (response.ok) {
            alert('Thank you for your message! We\'ll get back to you soon.');
            document.querySelector('.contact-form').reset();
        } else {
            alert('Sorry, there was an error sending your message. Please try again.');
        }
    } catch (error) {
        console.error('Form submission error:', error);
        alert('Sorry, there was an error sending your message. Please try again.');
    }
}