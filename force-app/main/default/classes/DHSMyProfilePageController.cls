/**
 * An apex class that updates portal user details.
   Guest users are never able to access this page.
 */
public with sharing class DHSMyProfilePageController {

    private User user;
    private boolean isEdit = false;

    /**
     * Returns the profile record for the current user.
     * @return Current user's profile record.
     */
    public User getUser() {
        return user;
    }

    /** Loads the current user's editable profile details. */
    public DHSMyProfilePageController() {
        user = [SELECT id, email, username, usertype, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId() WITH USER_MODE];
        // guest users should never be able to access this page
        if (user.usertype == 'GUEST') {
            throw new NoAccessException();
        }
    }

    /**
     * Indicates whether the profile is currently editable.
     * @return True while edit mode is enabled.
     */
    public Boolean getIsEdit() {
        return isEdit;
    }

    /** Enables profile editing. */
    public void edit() {
        isEdit=true;
    }

    /** Saves the current profile values. */
    public void save() {
        try {
            Database.update(user, AccessLevel.USER_MODE);
            isEdit=false;
        } catch(DmlException e) {
            ApexPages.addMessages(e);
        }
    }

    /**
     * Returns the DHS password-change page.
     * @return DHS password-change page reference.
     */
    public PageReference changePassword() {
        return Page.DHSChangePassword;
    }

    /** Cancels editing and reloads the persisted profile. */
    public void cancel() {
        isEdit=false;
        user = [SELECT id, email, username, communitynickname, timezonesidkey, languagelocalekey, firstname, lastname, phone, title,
                street, city, country, postalcode, state, localesidkey, mobilephone, extension, fax, contact.email
                FROM User
                WHERE id = :UserInfo.getUserId() WITH USER_MODE];
    }    
}