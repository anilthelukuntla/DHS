/**
 * An apex page controller that supports self registration of users in communities that allow self registration
 */
public class CommunitiesSelfRegController {
    @TestVisible private static Boolean simulateSuccessfulRegistration = false;

    /** Registrant first name. */
    public String firstName {get; set;}
    /** Registrant last name. */
    public String lastName {get; set;}
    /** Registrant email and username. */
    public String email {get; set;}
    /** Requested password. */
    public String password {get; set {password = value == null ? value : value.trim(); } }
    /** Confirmation of the requested password. */
    public String confirmPassword {get; set { confirmPassword = value == null ? value : value.trim(); } }
    /** Registrant community nickname. */
    public String communityNickname {get; set { communityNickname = value == null ? value : value.trim(); } }
    
    /** Initializes the Experience Cloud context from the request parameter. */
    public CommunitiesSelfRegController() {
        String expid = ApexPages.currentPage().getParameters().get('expid');            
        if (expId != null) {
            Site.setExperienceId(expId); 
        }    
    }
    
    private boolean isValidPassword() {
        return password == confirmPassword;
    }

    /**
     * Registers and optionally logs in the external user.
     * @return login, confirmation, or current page depending on the registration outcome
     */
    public PageReference registerUser() {
    
           // it's okay if password is null - we'll send the user a random password in that case
        if (!isValidPassword()) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, Label.site.passwords_dont_match);
            ApexPages.addMessage(msg);
            return null;
        }    

        String profileId = null; // To be filled in by customer.
        String accountId = ''; // To be filled in by customer.
        
        String userName = email;

        User u = new User();
        u.Username = userName;
        u.Email = email;
        u.FirstName = firstName;
        u.LastName = lastName;
        u.CommunityNickname = communityNickname;
		u.ProfileId = profileId;
		
        String userId;

        try {
            userId = Test.isRunningTest() && simulateSuccessfulRegistration
                ? UserInfo.getUserId()
                : Site.createExternalUser(u, accountId, password);
        } catch(Site.ExternalUserCreateException ex) {
            List<String> errors = ex.getDisplayMessages();
            for (String error : errors)  {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
            }
            
            // This message is used for debugging. Do not display this in the UI to the end user.
            // It has the information around why the user creation failed.
        }
        
        if (userId != null) { 
            if (password != null && password.length() > 1) {
                return Site.login(userName, password, ApexPages.currentPage().getParameters().get('startURL'));
            }
            else {
                PageReference page = System.Page.CommunitiesSelfRegConfirm;
                page.setRedirect(true);
                return page;
            }
        }
        return null;
    }
}