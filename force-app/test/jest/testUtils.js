export const flushPromises = () =>
    new Promise((resolve) => {
        setTimeout(resolve, 0);
    });

export const clearDom = () => {
    while (document.body.firstChild) {
        document.body.removeChild(document.body.firstChild);
    }
};
