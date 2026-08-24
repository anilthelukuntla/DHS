/**
 * @description Controller for editing and deleting DHS case messages.
 */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSCaseMessageEditorController {
    
    /** @description Provides this DHS API member. */
    public String caseId { get; set; }
    /** @description Provides this DHS API member. */
    public String messageId { get; set; }
    /** @description Provides this DHS API member. */
    public String editedSubject { get; set; }
    /** @description Provides this DHS API member. */
    public String editedBody { get; set; }
    /** @description Provides this DHS API member. */
    public String errorMessage { get; set; }
    public Boolean hasError { get; set; } // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    
    // User profile checks
    /** @description Provides this DHS API member. */
    public Boolean isCMOOrPMO { 
        get {
            String userType = [SELECT User_Type__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1].User_Type__c;
            return userType == 'CMO' || userType == 'PMO';
        }
    }
    
    /** @description Provides this DHS API member. */
    public Boolean isInvestigator { 
        get {
            String userType = [SELECT User_Type__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1].User_Type__c;
            return userType == 'INV';
        }
    }
    
    /** @description Provides this DHS API member. */
    public DHSCaseMessageEditorController() {
        hasError = false;
        errorMessage = '';
    }
    
    /**
     * @description Provides this DHS API member.
     * @return The requested result.
     */
    public PageReference saveMessage() {
        try {
            // Get current user info
            User currentUser = [SELECT Id, User_Type__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            
            // Get the message to edit
            DHS_Message__c messageToEdit = [SELECT Id, Subject__c, Message_Body__c, DHS_From_User__c, DHS_Case__c 
                                       FROM DHS_Message__c 
                                       WHERE Id = :messageId
                                       WITH USER_MODE LIMIT 1];
            
            // Check permissions
            if (!hasEditPermission(currentUser, messageToEdit)) {
                hasError = true;
                errorMessage = 'You do not have permission to edit this message.';
                return null;
            }
            
            // Update the message
            messageToEdit.Subject__c = editedSubject;
            messageToEdit.Message_Body__c = editedBody;
            
            Database.update(messageToEdit, AccessLevel.USER_MODE);
            
            hasError = false;
            errorMessage = '';
            
            return null;
            
        } catch (Exception e) {
            hasError = true;
            errorMessage = 'Error saving message: ' + e.getMessage();
            return null;
        }
    }
    
    private Boolean hasEditPermission(User currentUser, DHS_Message__c message) {
        // CMO and PMO can edit all messages
        if (currentUser.User_Type__c == 'CMO' || currentUser.User_Type__c == 'PMO') {
            return true;
        }
        
        // Investigators can only edit their own messages
        if (currentUser.User_Type__c == 'INV') {
            return message.DHS_From_User__c == currentUser.Id;
        }
        
        // Other user types cannot edit
        return false;
    }
    
    /**
     * @description Provides this DHS API member.
     * @param messageId Method parameter.
     * @return The requested result.
     */
    public static Boolean canDeleteMessage(String messageId) {
        try {
            User currentUser = [SELECT Id, User_Type__c FROM User WHERE Id = :UserInfo.getUserId() WITH USER_MODE LIMIT 1];
            
            // Only CMO and PMO can delete messages
            return currentUser.User_Type__c == 'CMO' || currentUser.User_Type__c == 'PMO';
            
        } catch (Exception e) {
            return false;
        }
    }
    
    @RemoteAction
    /**
     * @description Provides this DHS API member.
     * @param messageId Method parameter.
     */
    public static void deleteMessage(String messageId) {
        try {
            // Check if user can delete
            if (!canDeleteMessage(messageId)) {
                throw new AuraHandledException('You do not have permission to delete messages.');
            }
            
            DHS_Message__c messageToDelete = [SELECT Id FROM DHS_Message__c WHERE Id = :messageId WITH USER_MODE LIMIT 1];
            Database.delete(messageToDelete, AccessLevel.USER_MODE);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting message: ' + e.getMessage());
        }
    }
}
