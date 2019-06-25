function refresh() {
    if (window.liveReloadPaused) {
        console.log('liveReloadPaused');
        return;
    }

    fetch(window.location.href, {credentials: 'include'})
        .then(response => { if (response.ok) return response.text(); else throw Error(response.statusText) })
        .catch(error => {
            console.log('Live Reload Failed', error);

            throw error;
        })
        .then(html => {
            var parser = new DOMParser();
            var dom = parser.parseFromString(html, 'text/html');
            morphdom(document.body, dom.body, {
                getNodeKey: function (el) {

                    var key = el.id;
                    if (el.id) {
                        key = el.id;
                    } else if (el.form && el.name) {
                        key = el.name + "_" + el.form.action;
                    } else if (el instanceof HTMLFormElement) {
                        key = "form#" + el.action;
                    } else if (el instanceof HTMLScriptElement) {
                        key = el.src;
                    }
                    return key;
                },
                onBeforeElChildrenUpdated: function(fromEl, toEl) {
                    if (fromEl.tagName === 'TEXTAREA' || fromEl.tagName === 'INPUT') {
                        toEl.checked = fromEl.checked;
                        toEl.value = fromEl.value;
                    } else if (fromEl.tagName === 'OPTION') {
                        toEl.selected = fromEl.selected;
                    }
                }
            });

            window.clearAllIntervals();
            window.clearAllTimeouts();
            
            var event = new CustomEvent('turbolinks:load', {});
            document.dispatchEvent(event);
        });
}

function startReloadListener() {
    var notificationSocket = new WebSocket("ws://localhost:8002");
    notificationSocket.onmessage = function (event) {
        if (event.data === 'reload') {
            refresh();
        }
    }
}

if (window.liveReloadEnabled) {

} else {
    window.liveReloadEnabled = true;
    startReloadListener();
}