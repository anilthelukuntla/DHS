/**
 * An apex page controller that exposes the site login functionality
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CommunitiesLoginController {
    
    /**
     * Forwards the user to the configured Experience Cloud authentication provider.
     * @return the authentication page selected by the platform
     */
    global PageReference forwardToAuthPage() {
    	String startUrl = System.currentPageReference().getParameters().get('startURL');
    	String displayType = System.currentPageReference().getParameters().get('display');
        return Network.forwardToAuthPage(startUrl, displayType);
    }
}