import { createElement } from 'lwc';
import IntelDeploymentSmoke from 'c/intelDeploymentSmoke';

describe('c-intel-deployment-smoke', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders the default deployment message', () => {
        const element = createElement('c-intel-deployment-smoke', {
            is: IntelDeploymentSmoke
        });

        document.body.appendChild(element);

        const card = element.shadowRoot.querySelector('lightning-card');
        const message = element.shadowRoot.querySelector('p');

        expect(card.title).toBe('INTEL Deployment Smoke Test');
        expect(message.textContent).toBe('INTELDEPLOYHUB deployment pipeline is ready.');
    });

    it('renders configured public values', () => {
        const element = createElement('c-intel-deployment-smoke', {
            is: IntelDeploymentSmoke
        });
        element.title = 'Custom Smoke Test';
        element.message = 'Custom deployment check.';

        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('lightning-card').title).toBe('Custom Smoke Test');
        expect(element.shadowRoot.querySelector('p').textContent).toBe('Custom deployment check.');
    });
});
