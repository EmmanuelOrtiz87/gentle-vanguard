// Dashboard Analytics - Track usage and performance
(function() {
    'use strict';
    
    const ANALYTICS_KEY = 'gv_dashboard_analytics';
    const SESSION_START = Date.now();
    
    // Analytics data structure
    let analytics = {
        sessionId: 'session-' + Date.now(),
        startTime: new Date().toISOString(),
        pageViews: {},
        interactions: [],
        performance: {
            loadTime: 0,
            renderTime: 0
        },
        errors: []
    };
    
    // Track page view
    function trackPageView(section) {
        if (!analytics.pageViews[section]) {
            analytics.pageViews[section] = { count: 0, time: 0 };
        }
        analytics.pageViews[section].count++;
        analytics.pageViews[section].lastView = Date.now();
    }
    
    // Track interaction
    function trackInteraction(type, target) {
        analytics.interactions.push({
            type: type,
            target: target,
            timestamp: Date.now(),
            sessionDuration: Date.now() - SESSION_START
        });
        
        // Keep only last 100 interactions
        if (analytics.interactions.length > 100) {
            analytics.interactions.shift();
        }
    }
    
    // Track error
    function trackError(error) {
        analytics.errors.push({
            message: error.message,
            stack: error.stack,
            timestamp: Date.now()
        });
        
        // Keep only last 50 errors
        if (analytics.errors.length > 50) {
            analytics.errors.shift();
        }
    }
    
    // Measure performance
    function measurePerformance() {
        if (window.performance) {
            const timing = window.performance.timing;
            analytics.performance.loadTime = timing.loadEventEnd - timing.navigationStart;
            analytics.performance.domReady = timing.domContentLoadedEventEnd - timing.navigationStart;
        }
    }
    
    // Save analytics
    function saveAnalytics() {
        try {
            localStorage.setItem(ANALYTICS_KEY, JSON.stringify(analytics));
        } catch (e) {
            console.error('[Analytics] Failed to save:', e);
        }
    }
    
    // Send analytics to server
    function sendAnalytics() {
        const data = {
            ...analytics,
            sessionDuration: Date.now() - SESSION_START,
            userAgent: navigator.userAgent,
            screenSize: `${window.innerWidth}x${window.innerHeight}`
        };
        
        // Send via beacon API for reliability
        if (navigator.sendBeacon) {
            navigator.sendBeacon('/api/analytics', JSON.stringify(data));
        } else {
            // Fallback to fetch
            fetch('/api/analytics', {
                method: 'POST',
                body: JSON.stringify(data),
                headers: { 'Content-Type': 'application/json' },
                keepalive: true
            }).catch(() => {});
        }
    }
    
    // Track section views
    function setupSectionTracking() {
        const sections = document.querySelectorAll('.sec');
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    trackPageView(entry.target.id);
                }
            });
        }, { threshold: 0.5 });
        
        sections.forEach(section => observer.observe(section));
    }
    
    // Track button clicks
    function setupClickTracking() {
        document.addEventListener('click', (e) => {
            const target = e.target.closest('button, a, [role="button"]');
            if (target) {
                trackInteraction('click', target.textContent || target.id || 'unknown');
            }
        });
    }
    
    // Track errors
    function setupErrorTracking() {
        window.addEventListener('error', (e) => {
            trackError(e.error);
        });
        
        window.addEventListener('unhandledrejection', (e) => {
            trackError({ message: e.reason, stack: '' });
        });
    }
    
    // Initialize
    function init() {
        measurePerformance();
        setupSectionTracking();
        setupClickTracking();
        setupErrorTracking();
        
        // Save analytics periodically
        setInterval(saveAnalytics, 30000);
        
        // Send on page unload
        window.addEventListener('beforeunload', () => {
            saveAnalytics();
            sendAnalytics();
        });
        
        // Track initial section
        const activeSection = document.querySelector('.sec.active');
        if (activeSection) {
            trackPageView(activeSection.id);
        }
        
        console.log('[Analytics] Initialized');
    }
    
    // Export for debugging
    window.GV_ANALYTICS = {
        getData: () => analytics,
        trackPageView: trackPageView,
        trackInteraction: trackInteraction,
        send: sendAnalytics
    };
    
    // Start when DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
