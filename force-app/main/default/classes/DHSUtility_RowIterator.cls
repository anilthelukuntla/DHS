/**
 * @description Retains the existing DHSUtility_RowIterator integration and application behavior.
 */

public with sharing class DHSUtility_RowIterator implements iterator<String>, Iterable<String>
{
   private String mData;
   private Integer mIndex = 0;
   private String mRowDelimiter = '\n';
    
 
   /**
    * @description Provides this DHS API member.
    * @param fileData Method parameter.
    * @param rowDelimiter Method parameter.
    */
   public DHSUtility_RowIterator(String fileData, String rowDelimiter)
   {
      mData = fileData; 
      mRowDelimiter = rowDelimiter;
   }
 
    
   /**
    * @description Provides this DHS API member.
    * @return The requested result.
    */
   public Boolean hasNext()
   {
      return mIndex < mData.length() ? true : false;
   }
   /**
    * @description Provides this DHS API member.
    * @return The requested result.
    */
   public String next()
   {     
      Integer key = mData.indexOf(mRowDelimiter, mIndex);
       
      if (key == -1) {
        key = mData.length();
      }
             
      String row = mData.subString(mIndex, key);
      mIndex = key + 1;
      return row;
   }
   /**
    * @description Provides this DHS API member.
    * @return The requested result.
    */
   public iterator<String> iterator()
   {
      return this;   
   }
}
