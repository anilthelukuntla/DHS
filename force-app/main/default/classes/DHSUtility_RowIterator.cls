/** Retains the existing DHSUtility_RowIterator integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc')
public with sharing class DHSUtility_RowIterator implements iterator<String>, Iterable<String>
{
   private String mData;
   private Integer mIndex = 0;
   private String mRowDelimiter = '\n';
    
 
   public DHSUtility_RowIterator(String fileData, String rowDelimiter)
   {
      mData = fileData; 
      mRowDelimiter = rowDelimiter;
   }
 
    
   public Boolean hasNext()
   {
      return mIndex < mData.length() ? true : false;
   }
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
   public iterator<String> iterator()
   {
      return this;   
   }
}
