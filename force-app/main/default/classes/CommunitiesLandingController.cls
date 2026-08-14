/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
public with sharing class CommunitiesLandingController {
    
    /**
     * Directs the user to the appropriate Experience Cloud start page.
     * @return the community landing page selected by the platform
     */
    public PageReference forwardToStartPage() {
        return Network.communitiesLanding();
    }
}