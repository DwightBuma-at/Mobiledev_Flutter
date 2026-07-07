(function () {
    function readSignature(keys) {
        return keys.map(key => `${key}:${localStorage.getItem(key) || ''}`).join('|');
    }

    function watch(keys, callback, options) {
        const settings = options || {};
        const intervalMs = settings.intervalMs || 1000;
        let signature = readSignature(keys);
        let timer = null;


        function runIfChanged(force) {
            const nextSignature = readSignature(keys);
            if (!force && nextSignature === signature) return;
            signature = nextSignature;
            window.clearTimeout(timer);
            timer = window.setTimeout(callback, 80);
        }

        window.addEventListener('storage', event => {
            if (!event.key || keys.includes(event.key)) runIfChanged(true);
        });

        window.addEventListener('focus', () => runIfChanged(false));
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden) runIfChanged(false);
        });

        window.setInterval(() => runIfChanged(false), intervalMs);
    }

    async function clearWebsiteCache() {
        const confirmed = window.confirm('Clear all saved website data and refresh the system? This will remove residents, blotters, events, certificates, officials, and current login data.');
        if (!confirmed) return;

        try {
            localStorage.clear();
            sessionStorage.clear();

            if ('caches' in window) {
                const cacheNames = await caches.keys();
                await Promise.all(cacheNames.map(name => caches.delete(name)));
            }

            if ('serviceWorker' in navigator) {
                const registrations = await navigator.serviceWorker.getRegistrations();
                await Promise.all(registrations.map(registration => registration.unregister()));
            }
        } catch (error) {
            console.warn('Cache clear completed with warnings:', error);
        }

        window.location.href = new URL(`../index.html?refresh=${Date.now()}`, window.location.href).href;
    }

    window.BimsRealtime = { watch };
    window.clearWebsiteCache = clearWebsiteCache;
})();
