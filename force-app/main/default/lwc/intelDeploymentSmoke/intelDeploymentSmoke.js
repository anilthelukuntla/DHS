import { LightningElement, api } from 'lwc';

export default class IntelDeploymentSmoke extends LightningElement {
    @api title = 'INTEL Deployment Smoke Test';
    @api message = 'INTELDEPLOYHUB deployment pipeline is ready.';
}
