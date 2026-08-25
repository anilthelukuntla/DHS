/**
 * @description Provides reusable Salesforce Files creation and linking operations.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.UnusedMethod')
public class DHSFilesRecipes {
    /**
     * @description Provides this DHS API member.
     * An inner class representing a file to be created and linked to a given record.
     * Useful for bulk-creating files and linking them.
     */
    public class FileAndLinkObject {
        /** @description Provides this DHS API member. */
        public Blob fileContents { get; set; }
        /** @description Provides this DHS API member. */
        public Id attachedTo { get; set; }
        /** @description Provides this DHS API member. */
        public String fileName { get; set; }
    }

    /**
     * @description Internal exception class
     */
    public class FilesRecipesException extends Exception {
    }
    /**
     * @description This enum encapsulates a 'generic' filetype a 'filetype'
     * that may have multiple file extension and mime types associated with it.
     * For instance, IMAGE encapsulates: jpg, gif, jpeg, & png this allows
     * developers to say, 'give me all *image* attachments' without worrying
     * about the actual file extension.
     */
    public enum GenericFileType {
        IMAGE,
        AUDIO,
        DOCUMENT,
        ALL
    }

    /**
     * @description creates a file attachment containing the given string and
     * links it to the object specified in firstLocation
 * @param  text          String to write to the file
 * @param  firstLocation object to immediately link this file to
     * @example
     * ```
     * Account acct = [SELECT Id FROM Account LIMIT 1];
     * DHSFilesRecipes.createFileFromStringAttachedToRecord('Hello World', acct.Id);
     * 
     * ```
     */
    public static void createFileFromStringAttachedToRecord(
        String text,
        Id firstLocation
    ) {
        Blob fileContents = Blob.valueOf(text);
        DHSFilesRecipes.createFileAttachedToRecord(
            fileContents,
            firstLocation,
            'AwesomeFile1'
        );
    }

    /**
     * @description        Creates a file and links it to a given record
 * @param fileContents the binary blob of the files contents
 * @param attachedTo   the record to link this file to, initially
 * @param fileName     the name of the file. Note that the system determines
     *  the filetype from the file extension here
     * @example
     * ```
     * Blob fileContents = Blob.valueOf('Hello World 2');
     * Account acct = [SELECT Id FROM Account LIMIT 1];
     *  DHSFilesRecipes.createFileAttachedToRecord(
     *      fileContents,
     *      firstLocation,
     *      'AwesomeFile1'
     *  );
     * 
     * ```
 * @return The requested result.
 * @return The requested result.
     */
    public static Database.SaveResult createFileAttachedToRecord(
        Blob fileContents,
        Id attachedTo,
        String fileName
    ) {
        ContentVersion fileToUpload = new ContentVersion();
        // S = Salesforce. The other options are: 'E' (external)
        // and 'L' (social customer service)
        fileToUpload.ContentLocation = 'S';
        fileToUpload.PathOnClient = fileName;
        fileToUpload.Title = fileName;
        fileToUpload.VersionData = fileContents;
        fileToUpload.FirstPublishLocationId = attachedTo;
        Database.SaveResult saveResult;
        saveResult = Database.insert(fileToUpload, AccessLevel.USER_MODE);
        return saveResult;
    }

    /**
     * @description    Convenience method for creating a file and linking it to a given record
 * @param toCreate a FileAndLinkObject (inner class above) object representing the file to be created and linked
 * @return The requested result.
     */
    public static Database.SaveResult createFileAttachedToRecord(
        DHSFilesRecipes.FileAndLinkObject toCreate
    ) {
        return createFileAttachedToRecord(
            toCreate.fileContents,
            toCreate.attachedTo,
            toCreate.fileName
        );
    }

    /**
     * @description    Bulk method for inserting multiple files and link them to records
 * @param toCreate
 * @return The requested result.
     */
    public static List<Database.SaveResult> createFilesAttachedToRecords(
        List<DHSFilesRecipes.FileAndLinkObject> toCreate
    ) {
        List<ContentVersion> filesToCreate = new List<ContentVersion>();
        for (DHSFilesRecipes.FileAndLinkObject files : toCreate) {
            ContentVersion fileToUpload = new ContentVersion();
            fileToUpload.ContentLocation = 'S';
            fileToUpload.PathOnClient = files.fileName;
            fileToUpload.Title = files.fileName;
            fileToUpload.VersionData = files.fileContents;
            fileToUpload.FirstPublishLocationId = files.attachedTo;
            filesToCreate.add(fileToUpload);
        }

        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();
        saveResult = Database.insert(filesToCreate, AccessLevel.USER_MODE);
        return saveResult;
    }

    /**
     * @description Searches for content version records linked to this record
     * Filtering by a generic file type: image, audio, document etc.
     *
     * Note: This method has a false-positive PMD warning. Our Query
     * includes the keyword 'WITH USER_MODE' which prevents this
     * Query from accessing fields and objects that they don't have permission
     * to access. This is a form of inline CRUD/FLS Check.
     *
 * @param genericFileType Enum of image, audio, document
 * @param recordId        Record ID to limit searching to
     * @example
     * ```
     * Account acct = [SELECT Id FROM Account LIMIT 1];
     * DHSFilesRecipes.createFileFromStringAttachedToRecord('Hello World', acct.Id);
     * 
     * ```
 * @return The requested result.
     */
    public static List<ContentVersion> getFilteredAttachmentsForRecord(
        DHSFilesRecipes.GenericFileType genericFileType,
        Id recordId
    ) {
        Map<String, Object> recordBind = new Map<String, Object>{
            'recordId' => recordId
        };
        List<ContentDocumentLink> links = new List<ContentDocumentLink>();
        String queryString =
            'SELECT ContentDocumentId' +
            ' FROM ContentDocumentLink' +
            ' WHERE ' +
            ' LinkedEntityId = :recordId';

        switch on genericFileType {
            when AUDIO {
                queryString += ' AND ContentDocument.FileType IN (\'M4A\')';
            }
            when IMAGE {
                queryString += ' AND ContentDocument.FileType IN (\'JPG\', \'GIF\', \'PNG\', \'JPEG\')';
            }
            when DOCUMENT {
                queryString += ' AND ContentDocument.FileType IN (\'WORD_X\', \'EXCEL_X\', \'POWER_POINT_X\', \'PDF\')';
            }
            when ALL {
                queryString += '';
            }
        }
        links = Database.queryWithBinds(
            queryString,
            recordBind,
            AccessLevel.USER_MODE
        );

        Set<Id> fileIds = new Set<Id>();
        for (ContentDocumentLink cdl : links) {
            fileIds.add(cdl.ContentDocumentId);
        }
        return [
            SELECT Id, Title
            FROM ContentVersion
            WHERE ContentDocumentId IN :fileIds AND IsLatest = TRUE
            WITH USER_MODE
            ORDER BY CreatedDate
        ];
    }

    /**
     * @description Given a content document link, publish the content version
 * @param cdl   Content Document link record to publish
     * @exception   FilesRecipesException
     * @example
     * ```
     * Account acct = [SELECT Id FROM Account LIMIT 1];
     * DHSFilesRecipes.createFileFromStringAttachedToRecord('Hello World', acct.Id);
     * ContentDocumentLink cdl = [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId = :acct.id LIMIT 1];
     *
     * ```
 * @return The requested result.
     */
    public static Database.SaveResult publishContent(ContentDocumentLink cdl) {
        ContentDistribution dist = new ContentDistribution();

        dist.Name = 'new distributrion of content';
        dist.PreferencesAllowOriginalDownload = true;
        dist.PreferencesAllowPDFDownload = true;
        dist.PreferencesAllowViewInBrowser = true;
        dist.RelatedRecordId = cdl.LinkedEntityId;
        dist.ContentVersionId = cdl.ContentDocument.LatestPublishedVersionId;

        try {
            return Database.insert(dist, AccessLevel.USER_MODE);
        } catch (DmlException DMLe) {
            throw new FilesRecipesException(DMLe.getMessage());
        }
    }
}