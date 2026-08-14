/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
public with sharing class CommunitiesSelfRegConfirmController {
    @TestVisible private Boolean confirmationPageReady;

    /**
     * Explicit constructor retained for the Visualforce controller contract.
     */
    public CommunitiesSelfRegConfirmController() {
        confirmationPageReady = true;
    }
}