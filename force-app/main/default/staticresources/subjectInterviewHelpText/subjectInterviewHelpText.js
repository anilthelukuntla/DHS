



$(document).ready(function() {
  const data = [
      {
        "value1": "Report any additional names used, what the name was used for, time frame of use and whether the additional names were used on any legal documents. Report details surrounding the use of any other names listed on the case papers.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not used any other names.",
        "value3": "The information listed on the SF86 is correct. SUBJECT goes by XXXX because XXXX (reason). SUBJECT signs all legal documents with (his/her) full legal name exclusively."
      },
      {
        "value1": "Report any additional names used, what the name was used for, time frame of use and whether the additional names were used on any legal documents. Report details surrounding the use of any other names listed on the case papers.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not used any other names.",
        "value3": "The information listed on the SF86 is correct. SUBJECT goes by XXXX because XXXX (reason). SUBJECT signs all legal documents with (his/her) full legal name exclusively."
      },
      {
        "value1": "The current/most recent education name, date and location is reported. Report if education within the last 3 years is primary activity or not. Leads will be needed for anything primary within the 3 year timeframe for 2 direct sources. Report any changes and/or discrepancies for any listed education. Clarify if education was online, in person, or both. For all developed educations, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has no other education to report. SUBJECT has had no issues with any education to include any suspensions, expulsions, academic probations, or problems with attendance. SUBJECT has not studied abroad. No student or instructor has any reason to question SUBJECT's conduct or behavior.",
        "value3": "The information listed on the SF86 is correct. SUBJECT’s foreign education in NAME OF COUNTRY from XX/XXXX to XX/XXXX was organized by XXXX and funded by XXXX. SUBJECT studied abroad because XXXX. Unless otherwise documented, SUBJECT denied any interaction with foreign government, law enforcement, local customs, or security officials while overseas. Additionally, no one exhibited excessive knowledge of or undue interest in SUBJECT while living overseas. SUBJECT has had no issues to include any suspensions, expulsions, academic probations, or problems with attendance. No student or instructor has any reason to question SUBJECT's conduct or behavior.",
        "value4": "EXAMPLE if discrepancy exist: SUBJECT attended Webster University entirely online and received a master’s degree in Legal Studies in 8/2008. SUBJECT did not list her attendance as being online due to oversight and SUBJECT listed the date she received her degree incorrectly on the SF86 due to a typographical error.",
        "value5": "If no discrepancy: Subject attended Webster University as their primary activity in the last 3 years with leads xyz and no other leads. SUBJECT has no other education to report. SUBJECT has had no issues related to education to include any suspensions, expulsions, academic probations, or problems with attendance. SUBJECT has not done any study abroad. No student or instructor has any reason to question SUBJECT's conduct or behavior."
      },
      {
        "value1": "Report each employment name within the last 7 years as verified in the ROI. Include the W-2 employments shown on any records SUBJECT could provide within 7 years and disclaim if none could be provided then or at a later date. Report any changes and/or discrepancies for any listed employment. For all developed employments, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the disclaimer below if applicable and adjust the disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. For all of SUBJECT’s employments, SUBJECT has never been fired or quit after being told SUBJECT would be fired. SUBJECT has never left an employer due to mutual agreement because of employee misconduct or unsatisfactory performance. SUBJECT has never received a written warning or reprimand at any employment. No one would have any reason to question SUBJECT's conduct or behavior. SUBJECT has not violated any oral or written employment policies. SUBJECT has had no security violations. SUBJECT is eligible for rehire and has not left any employment under any unfavorable circumstances.",
        "value3": "EXAMPLE of developed/unlisted employment: From 5/2019 to 4/2021, SUBJECT was employed full time as an Investigator for Ultimate Investigations, LLC located at 635 Main Street Roblox, IN 27363, telephone number 548-658-5487. SUBJECT did not list this employment on the SF86 because he forgot. This was a federal contractor employment. SUBJECT worked remotely from his home the entire employment period and had no direct contact with co-workers. SUBJECT’s supervisor was Field Manager Charles Howell located in Harrisburg, PA 73629, telephone number 254-859-5477. SUBJECT worked remotely with co-workers Michael Ward, telephone number 827-387-3928 and Jimmy Smarty, telephone number 287-886-9987. SUBJECT does not know an address for Ward or Smarty. SUBJECT could not provide any additional employment leads.",
        "value4": "Example if no discrepancy: Subject worked at Ultimate Investigations as correctly listed. SUBJECT has no other employments to list. SUBJECT has never been fired or quit after being told SUBJECT would be fired. SUBJECT has never left an employer due to mutual agreement because of employee misconduct or unsatisfactory performance. SUBJECT has never received a written warning or reprimand at any employment. No one would have any reason to question SUBJECT's conduct or behavior. SUBJECT has not violated any oral or written employment policies. SUBJECT has had no security violations. SUBJECT is eligible for rehire and has not left any employment under any unfavorable circumstances."
      },
      {
        "value1": "Report the name of the self-employment as verified (see employment example.) Show the review of W-2 and/or business license or SUBJECT’S inability to obtain it then or in the near future. Report any changes and/or discrepancies for any listed self-employment. Clarify if it is actual self-employment or 1099 contractor status. For all developed self-employments, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the disclaimer below if applicable and adjust the disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any. Leads for self-employment could be clients, customers, vendors, etc.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has no self-employment."
      },
      {
        "value1": "Report means of support and activities SUBJECT was involved in while unemployed for each period listed. Report any changes and/or discrepancies for any listed unemployment. For all developed periods of unemployment, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report leads who can corroborate unemployment periods requiring coverage and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has no unemployment.",
        "value3": "SUBJECT was unemployed from XX/XXXX to XX/XXXX because XXXX. While unemployed, SUBJECT spent (his/her) time (REPORT PRIMARY ACTIVITY/HOW THEY SPENT THEIR TIME) and was financially supported by (REPORT HOW FINANCIALLY SUPPORTED). The following individuals would be aware of SUBJECT’s unemployment; (REPORT NAMES and CONTACT INFORMATION OF LEADS)"
      },
      {
        "value1": "Review the DD214 or disclaim why one could not be provided or why not able to be provided at a later date. Report any changes and/or discrepancies for any listed military service or federal employment. For any developed, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the disclaimer below if applicable and adjust the disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has no military service and no federal employment.",
        "value3": "The information listed on the SF86 is correct. SUBJECT’s DD-214 was reviewed and matches the information listed on the SF86."
      },
      {
        "value1": "During the interview, the investigator will go to sss.gov on their phone and confirm the listed number from the case papers and report that they did so. Report any discrepancies and clarify necessary information. Report the disclaimer below if applicable and adjust the disclaimer as needed to represent your Subject’s answers.",
        "value2": "SUBJECT is registered with the selective service system as verified by investigator at SSS.gov and all information listed on the SF86 is correct.",
        "value3": "SUBJECT does not have to register with the selective service system because XXXX.",
        "value4": "SUBJECT is registered with the selective service system and his number is XXXX. SUBJECT did not list his selective service number on the case papers because XXXX. Investigator verified this number at SSS.gov."
      },
      {
        "value1": "A character reference is any person that has substantive knowledge of SUBJECT, which is knowledge of SUBJECT beyond their primary activity association. To meet qualifications of a character reference, a Source should have first-hand knowledge of another primary activity (residence, education, employment) OR have social interaction with SUBJECT OR know SUBJECT well enough to speak informatively about SUBJECT’s character, conduct, and honesty. Briefly report the type and frequency of contact each listed reference has with SUBJECT.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has contact with listed reference (FIRST AND LAST NAME OF LISTED REFERENCE #1) approximately (FREQUENCY OF CONTACT). SUBJECT has contact with listed reference (FIRST AND LAST NAME OF LISTED REFERENCE #2) approximately (FREQUENCY OF CONTACT). SUBJECT has contact with listed reference (FIRST AND LAST NAME OF LISTED REFERENCE #3) approximately (FREQUENCY OF CONTACT). SUBJECT provided (NAME, telephone number XXX-XXX-XXXX,) as another reference who SUBJECT has had contact with (FREQUENCY OF CONTACT) since approximately (SPAN OF CONTACT).",
        "value3": "The information listed on the SF86 is correct. SUBJECT has contact with listed reference (FIRST AND LAST NAME OF LISTED REFERENCE #1) approximately (FREQUENCY OF CONTACT). SUBJECT has contact with listed reference (FIRST AND LAST NAME OF LISTED REFERENCE #2) approximately (FREQUENCY OF CONTACT). SUBJECT has contact with listed reference (FIRST AND LAST NAME OF LISTED REFERENCE #3) approximately (FREQUENCY OF CONTACT). SUBJECT could not provide any additional references."
      },
      {
        "value1": "Report any changes, discrepancies, and issue resolution for all spouses/former spouses/children. For any developed information, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT is married to (NAME OF SPOUSE) and has (NO or # of CHILD(REN) and include their names).",
        "value3": "The information listed on the SF86 is correct. SUBJECT has never been married and has no children.",
        "value4": "The information listed on the SF86 is correct. SUBJECT divorced (NAME OF FORMER SPOUSE) because (REASON FOR DIVORCE). SUBJECT denies any abuse allegations and is abiding by all financial and custodial obligations."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed relatives/associates. For any developed relatives/associates, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report all leads and disclaim lack of leads if SUBJECT could not provide any. If any relative/associate is foreign, foreign born and/or dual citizen, confirm all listed information, report basic details for each person to provide context and report the applicable disclaimer from below adjusting each disclaimer as needed to represent your Subject’s answers.",
        "value2": "The information listed on the SF86 is correct. SUBJECT’s relatives are United States citizens. Unless otherwise documented, none of SUBJECT’s relatives have any ties to a foreign government and SUBJECT has no reason to question their loyalty to the U.S. None of SUBJECT’s relatives have been arrested or convicted of a criminal offense or been involved in undetected criminal activity known to SUBJECT.",
        "value3": "The information listed on the SF86 is correct. *Document (name and details xyz) were sight verified for relative (name). SUBJECT’s (RELATIVE, NAME) is a U.S. naturalized citizen born in (FOREIGN COUNTRY). (NAME) immigrated to the U.S in (DATE) and pursued naturalization because XXXX. Their occupation in their former country was XXXX. SUBJECT has contact with (NAME) (FREQUENCY OF CONTACT). Unless otherwise documented, SUBJECT’s relative does not have any ties to a foreign government and SUBJECT has no reason to question their loyalty to the U.S.",
        "value4": "The information listed on the SF86 is correct. * Legal status document verification of foreign family living in the US is required, including spouse. SUBJECT’s (RELATIVE, NAME) is a foreign citizen of (COUNTRY). (NAME) resides (CITY/ST/COUNTRY OF RESIDENCE). SUBJECT expects to have contact with (NAME) (FREQUENCY/METHOD OF FUTURE CONTACT) going forward. Unless otherwise documented, SUBJECT's relative is not aware of SUBJECT’s U.S. Government affiliation; has not asked any suspicious or probing questions; does not harbor any animosity towards the U.S.; and has no influence over SUBJECT’s loyalty or willingness to protect classified information.",
        "value5": "EXAMPLE of developed U.S. relative not listed on SF86, and all relatives are U.S citizens: Leslie Hope, born 07/04/1984 in Cambridge, MD is SUBJECT’s half-sister. Hope has not used any other names and is a citizen of the United States residing at 3726 Freedom Way Carlisle, PA 83726. SUBJECT did not list Hope on the SF86 due to oversight. SUBJECT has no additional relatives. SUBJECT’s relatives are United States citizens. Unless otherwise documented, none of SUBJECT’s relatives have any ties to a foreign government and SUBJECT has no reason to question their loyalty to the U.S. None of SUBJECT’s relatives have been arrested or convicted of a criminal offense or been involved in undetected criminal activity known to SUBJECT.",
        "value6": "EXAMPLE of developed U.S. naturalized relative not listed on SF86, and no to all issue resolution questions: Leslie Hope, born 07/04/1984 in Dublin, Ireland is SUBJECT’s half-sister. Hope has not used any other names and is a naturalized U.S. citizen from Ireland residing at 3726 Freedom Way Carlisle, PA 83726. SUBJECT did not list Hope on the SF86 due to oversight. Hope immigrated to the U.S in 2000 and pursued naturalization because she wanted better opportunities. Hope’s occupation in her former country was unemployed as she was a student. SUBJECT has contact with his sister weekly via phone and monthly in person. Unless otherwise documented, SUBJECT’s relative does not have any ties to a foreign government and SUBJECT has no reason to question their loyalty to the U.S. A review of Hope’s US Passport that she provided to subject shows name, date issued, date expired, document number via a photo subject had from sister."
      },
      {
        "value1": "Clarify that cohabitant is in a relationship with subject and not living there for convenience as a roommate. If not born in the US, proof of citizenship is required for cohabitant. Report any changes, discrepancies, and issue resolution for all cohabitants and/or roommates. For any developed cohabitant, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below. Report all leads and disclaim lack of leads if SUBJECT could not provide any. If cohabitant and/or roommates are associated with a foreign country, refer to the Foreign National Contact section. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "The information listed on the SF86 is correct. SUBJECT does not have a cohabitant.",
        "value3": "EXAMPLE if developed cohabitant: Jane Doe is SUBJECT’s cohabitant. SUBJECT did not list Doe on the SF86 because SUBJECT did not understand the question. Doe’s DOB is 11/11/2001, POB is Gaithersburg, MD, and Doe is a United States citizen. Doe’s SSN is 111-11-1111 and Doe has not used any other names."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed foreign contacts along with SUBJECT’s answers to all applicable Foreign Contact Issue Resolution questions. For any developed foreign contacts, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT does not maintain contact with any foreign national.",
        "value3": "The information listed on the SF86 is correct. Foreign national contact (FULL NAME OF FOREIGN CONTACT) is a citizen of (COUNTRY) and is SUBJECT’s (DESCRIBE RELATIONSHIP and HOW THEY KNOW EACH OTHER). This foreign contact resides in (CITY, ST, OR COUNTRY OF RESIDENCE). SUBJECT expects their contact to be (FREQUENCY/METHOD OF FUTURE CONTACT) going forward. Unless otherwise documented, the foreign contact is not aware of SUBJECT’s U.S. Government affiliation; has not asked any suspicious or probing questions; does not harbor any animosity towards the U.S.; and has no influence over SUBJECT’s loyalty or willingness to protect classified information.",
        "value4": "SUBJECT has had close and/or continuing contact with foreign national (FULL NAME OF FOREIGN NATIONAL) within the last seven years. SUBJECT did not list (LAST NAME OF CONTACT) as a foreign national contact because XXXX. (LAST NAME OF CONTACT) is a citizen of COUNTRY, born in (CITY, COUNTRY), date of birth is XX/XX/XXXX, address is XXXX and currently employed by (NAME AND ADDRESS OF EMPLOYER). (LAST NAME OF CONTACT) is SUBJECT’s (DESCIRBE RELATIONSHIP/HOW THEY KNOW EACH OTHER). SUBJECT first met (LAST NAME OF CONTACT) in approximately XX/XXXX and their last contact was in XX/XXXX during which time they maintained (FREQUENCY/METHOD OF CONTACT). SUBJECT expects them to have (FREQUENCY/METHOD OF FUTURE CONTACT) in the future because (REASON). (LAST NAME OF CONTACT) has not used any other names. Unless otherwise documented, the foreign contact is not aware of SUBJECT’s U.S. Government affiliation; has not asked any suspicious or probing questions; does not harbor any animosity towards the U.S.; and has no influence over SUBJECT’s loyalty or willingness to protect classified information. SUBJECT has not maintained close and/or continuing contact with any other foreign national."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed foreign activities along with SUBJECT’s answers to all applicable Foreign Activities Issue Resolution questions. For any developed foreign activities, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT does not own, control, or stand to inherit any foreign financial interests and SUBJECT’s relatives have not controlled such an interest on SUBJECT’s behalf. SUBJECT does not have a foreign business or foreign business connections, and SUBJECT has not been asked to provide advice or services to a foreign government. SUBJECT does not own or plan to purchase foreign property. SUBJECT has not received a benefit from a foreign country and SUBJECT’s relatives have not received a benefit from a foreign country. SUBJECT has not provided financial support to a foreign national, and SUBJECT has not sponsored a foreign national to come to the United States. SUBJECT has not participated in the political processes of a foreign country, and SUBJECT does not have a connection to a foreign government."
      },
      {
        "value1": "The stamps on the passport will be reported and compared to what is listed for any discrepancies. Report any changes and/or discrepancies for any listed foreign travel along with SUBJECT’s answers to all applicable Foreign Travel Issue Resolution questions. For any developed foreign travel, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not traveled to a foreign country within the last seven years.",
        "value3": "The information listed on the SF86 is correct. SUBJECT’s trip to (COUNTRY) from XX/XXXX to XX/XXXX was financed by XXXXX and for the purpose of XXXXX. SUBJECT traveled with (NAMES and CITIZENSHIP OF WHO TRAVELED WITH) and spent time (ACTIVITIES WHILE IN COUNTRY). SUBJECT resided in XXXXXX (hotel, AirBB, with so and so) and did/did not reside with any foreign nationals and the trip was not paid for by any foreign entity. While traveling in (COUNTRY), SUBJECT was not questioned, searched, or otherwise detained by the local law customs or security service officials when entering or leaving the country. SUBJECT was not involved in any encounter with the police. SUBJECT was not contacted by or in contact with any person known or suspected of being involved or associated with foreign intelligence, terrorist, security, or military organizations. SUBJECT was not involved in any counterintelligence or security issues. SUBJECT was not contacted by or in contact with anyone exhibiting excessive knowledge of or undue interest in SUBJECT’s job. SUBJECT was not contacted by or in contact with anyone attempting to obtain classified information or unclassified, sensitive information. SUBJECT was not threatened, coerced, or pressured in any way to cooperate with foreign government officials of foreign intelligence or security services. SUBJECT did not discuss their current processing for clearance with the U.S government or develop affinity or loyalty towards any foreign country.",
        "value4": "SUBJECT traveled to (COUNTRY) from XX/XXXX to XX/XXXX. SUBJECT did not list this travel on the SF86 because XXXX. The trip was financed by XXXXX for XXX reason. SUBJECT traveled with (NAMES and CITIZENSHIP OF WHO TRAVELED WITH) and spent time (ACTIVITIES WHILE IN COUNTRY). SUBJECT resided at XXXXX (hotel, AirBB, etc) and did/did not reside with any foreign nationals and the trip was not paid for by any foreign entity. While traveling in (COUNTRY), SUBJECT was not questioned, searched, or otherwise detained by the local law customs or security service officials when entering or leaving the country. SUBJECT was not involved in any encounter with the police. SUBJECT was not contacted by or in contact with any person known or suspected of being involved or associated with foreign intelligence, terrorist, security, or military organizations. SUBJECT was not involved in any counterintelligence or security issues. SUBJECT was not contacted by or in contact with anyone exhibiting excessive knowledge of or undue interest in SUBJECT’s job. SUBJECT was not contacted by or in contact with anyone attempting to obtain classified information or unclassified, sensitive information. SUBJECT was not threatened, coerced, or pressured in any way to cooperate with foreign government officials of foreign intelligence or security services. SUBJECT did not discuss their current processing for clearance with the U.S government or develop affinity or loyalty towards any foreign country."
      },
      {
       "value1":"" 
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed medical record information along with SUBJECT’s answers to all applicable Medical Record Issue Resolution questions. For any developed Medical Record information, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT did not report seeking or receiving assistance for a substantially adverse or otherwise reportable mental health concern or condition. SUBJECT did not report a condition that would alter SUBJECT’s behavior or impair SUBJECT’s judgment or ability to hold a security clearance with the United States government."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Criminal Activities along with SUBJECT’s answers to all applicable Criminal Issue Resolution questions. For any developed criminal activities, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not been cited, arrested, charged, convicted, or jailed for any criminal offense within scope of the investigation.",
        "value3": "CIVIL LITIGATION – Reporting Requirements: Report any changes and/or discrepancies for any listed Civil Actions along with SUBJECT’s answers to all applicable Civil Actions Issue Resolution questions. For any developed civil actions, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable The information listed on the SF86 is correct. SUBJECT has not been sued civilly. SUBJECT has not been party to any lawsuit. USE OF ILLEGAL SUBSTANCES and ACTIVITY – Reporting Requirements: Report any changes and/"
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Civil Actions along with SUBJECT’s answers to all applicable Civil Actions Issue Resolution questions. For any developed civil actions, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not been sued civilly. SUBJECT has not been party to any lawsuit."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Illegal Drug Use/Activity along with SUBJECT’s answers to all applicable Drug Issue Resolution questions. For any developed civil actions, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not used illegal drugs. SUBJECT has not used medication that was not prescribed to SUBJECT or in a manner inconsistent with medical direction. SUBJECT has not received treatment for drug-related problems. SUBJECT has not been involved in the possession, purchase, manufacture, trafficking, or sale of illegal drugs.",
        "value3": "EXAMPLE if Subject listed drug use: SUBJECT admitted to smoking marijuana a few times randomly during social gatherings. SUBJECT listed and verified HE smoked marijuana approximately three to four times between June 2016 to December 2021. SUBJECT remembers using marijuana once in California on vacation at a party in 2019 with HIS cousin, Jim Smith, telephone number 301-867-5309 and HIS sister, Maria System, telephone number 738-285-3827. For the other occasions HE used marijuana, SUBJECT was in a party setting with friends of associates, who SUBJECT does not recall names of. Each time SUBJECT used marijuana, it was smoked and always during random social events. SUBJECT does not recall how much marijuana was smoked each time. Marijuana did not have any effect on HIS behavior. Marijuana never had a negative impact on SUBJECT’s personality, reliability, work, school, home, family, or friends. SUBJECT has never been dependent on any drug. SUBJECT voluntarily chose to use marijuana because HE was curious. SUBJECT stopped using marijuana because HE never really enjoyed using it and it burned HIS throat. SUBJECT never purchased marijuana as each time SUBJECT smoked marijuana it was provided to HIM by other people. SUBJECT has never sold, supplied, manufactured, or grown drugs. No financial problems resulted from the drug use. SUBJECT has never been arrested, charged, or cited for drug use. SUBJECT has never tested positive on a drug test. SUBJECT’s cousin Jim Smith and sister Maria System are the only people aware of HIM using marijuana. SUBJECT no longer associates with anyone who uses illegal drugs. SUBJECT does not have any desire to use marijuana or any illegal drug in the future."
      },
      {
        "value1": "Watch carefully for underage drinking to resolve. Report any changes and/or discrepancies for any listed Alcohol issues along with SUBJECT’s answers to all applicable Alcohol Issue Resolution questions. For any developed civil actions, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT does not drink alcohol (because XXXX OR SUBJECT drinks (amount), (type of alcohol), (frequency). Alcohol consumption has never had a negative impact on SUBJECT’s professional or personal life. SUBJECT has not received treatment of alcohol-related problems. SUBJECT has never been told SUBJECT has a problem with alcohol.",
        "value3": "(See issue resolution guide for questions that should have been asked): Over the past five years, SUBJECT drinks (TYPE OF ALCOHOL and FREQUENCY or DOES NOT DRINK BECAUSE XXXX). SUBJECT consumed (HOW MUCH ALCOHOL CONSUMED EACH TIME) over a period of (HOURS SPENT CONSUMING THAT AMOUNT). SUBJECT typically consumes alcohol (LOCATIONS) with (WHO DRINKS WITH or ALONE). Based on the legal definition of intoxication, SUBJECT drinks alcohol to the point of intoxication (FREQUENCY). To become intoxicated, SUBJECT would need to consume approximately (NUMBER) glasses of (BEER, WINE, LIQUOR). The last time SUBJECT was intoxicated was (DATE) and SUBJECT consumed (NUMBER) of glasses of (BEER, WINE, LIQUOR). SUBJECT defines blackout as XXXX. SUBJECT would need to consume (NUMBER) of alcoholic drinks to blackout. SUBJECT blacks out (FREQUENCY). The last time SUBJECT blacked out was (DATE). SUBJECT’s use of alcohol (HAS or HAS NOT) resulted in receiving medical attention, counseling, or negative behaviors. SUBJECT (HAS or HAS NOT) driven while under the influence of alcohol to the point of impairment. SUBJECT’s motivation for drinking and becoming intoxicated IS or WAS XXXX. When under the influence of alcohol, SUBJECT is (DESCRIBE BEHAVIOR). SUBJECT (DOES or DOES NOT) feel HE/SHE has a problem with alcohol. SUBJECT’s future intentions regarding alcohol use are XXXX.",
      },
      {
      "value1": "OTHER INVESTIGATIONS – Reporting Requirements: Report any changes and/or discrepancies for any listed Other."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Other Investigations. For any developed Other Investigations, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not had a security clearance or access authorization denied, suspended, or revoked."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Financial Activity, along with SUBJECT’s answers to all applicable Financial Issue Resolution questions. For any developed financial information, to include financial delinquencies listed on the credit report, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT’s current financial situation is (DESCRIBE). SUBJECT has no bankruptcy, foreclosure, lien, garnishment, repossession, or collection accounts within scope of the investigation. SUBJECT has not experienced financial problems due to gambling. SUBJECT has paid all taxes. SUBJECT has no delinquent accounts.",
        "value3": "EXAMPLE unlisted account was over 120 days delinquent: SUBJECT’s credit card account with Chase Bank, account number 4738236485, is more than 120 days delinquent. SUBJECT did not list the account on the SF86 because SHE realized the account was delinquent after completing the case papers. The account was opened in approximately 2018 and is a joint account with SUBJECT’s former spouse, Mike Williams. The account became past due in approximately 1/2022 because SUBJECT forgot to pay the balance. The account is now approximately 6 months past due in the amount of $850. The account is currently delinquent as SUBJECT only realized the account was past due a few days ago when reviewing HER credit report. The total balance and amount past due are $850, which SUBJECT intends to pay in full next month, 7/2022, using money from HER savings. SUBJECT has not made any agreements or arrangements with the creditor. The account has not been placed in collections. SUBJECT can meet HER financial obligations. SUBJECT has not had any debts tied to events beyond HER control. SUBJECT has never participated in financial counseling or debt consolidation services. SUBJECT’s current financial situation is great as SHE has no other debts and has money in savings. SUBJECT is willing to live within HER means and satisfy all debts. No one would question SUBJECT’s ability or willingness to live with HER means or repay HER debts. The financial issue is not the result of criminal behavior or conduct. Only SUBJECT’s former spouse is aware of the chase account being delinquent. SUBJECT has not had any other financial problems or issues. SUBJECT has not had any other debt more than 120 days delinquent in the last seven years."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Misuse of Technology Systems along with SUBJECT’s answers to all applicable Issue Resolution questions. For any developed incidents of Misuse of Technology Systems, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers. Report all leads and disclaim lack of leads if SUBJECT could not provide any.",
        "value2": "The information listed on the SF86 is correct. SUBJECT has not engaged in illegal or unauthorized computer activity, such as accessing a computer system illegally or without authorization; modifying, destroying, manipulating, or denying access to a computer system illegally or without authorization; and introducing, removing, or using hardware, software, or media illegally or without authorization."
      },
      {
        "value1": "Report any changes and/or discrepancies for any listed Association Record information and responses to issue resolution questions for any issues. For any developed Association Record information, report complete details which SUBJECT would have been required to list on the case papers initially, along with the reason not listed. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "The information listed on the SF86 is correct. SUBJECT is not affiliated with, nor supports or sympathizes with, a group that advocates or engages in force, violent or subversive acts intended to coerce the conduct of government or overthrow the government. SUBJECT has not been a member of any organization seeking to deprive a person or group of their rights under the United States Constitution or that of any state. SUBJECT is a loyal United States citizen."
      },
      {
        "value1": "Media Publication Determine if SUBJECT has been or is currently involved or associated with any media outlet or media publication. If so, refer to the Issue Resolution guide for basic questions to ask and report, to include leads aware of SUBJECT’s involvement. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "SUBJECT has not been involved with the media and has not had any publications."
      },
      {
        "value1": "Report SUBJECT’s free time activities and how they spend their time outside of work. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "SUBJECT spends free time XXXX."
      },
      {
        "value1": "Report any positive responses to the concluding questions along with details and applicable issue resolution. If SUBJECT responded No to all concluding questions, report a brief disclaimer as listed below. Concluding questions can be found on the last page of the ESI Job Aid in ForeSite. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "SUBJECT otherwise responded with only favorable information regarding questions posed about SUBJECT’s conduct, employment, activities, and associates. SUBJECT had no additional questions or information to provide at the conclusion of the interview."
      },
      {
        "value1": "Report any changes and/or discrepancies regarding SUBJECT’s citizenship. Report complete details which SUBJECT would have been required to list on the case papers initially if citizenship status has changed or is different than listed on the SF86. Refer to the Issue Resolution Guide for questions to ask for full issue resolution of any issues as applicable. Report the applicable name, number, state, DOB, POB, etc.. and if the version of the birth certificate was or wasn’t the raised seal.",
        "value2": "The information listed on the SF86 is correct. SUBJECT is a United States citizen by birth as verified by document/passport (details entered here).",
        "value3": "The information listed on the SF86 is correct. SUBJECT immigrated to the U.S and pursued naturalization because XXXX. SUBJECT was sponsored to come to the U.S. by XXXX. SUBJECT’s occupation in (HIS/HER) former country was XXXX. Since becoming naturalized, SUBJECT (has OR has not) traveled to (HIS/HER) country of birth XXXX times because XXXX. Unless otherwise documented, SUBJECT does not intend to permanently return or retire in SUBJECT’s birth country or any other foreign country; does not maintain any loyalties to (HIS/HER) birth country; or identify with (HIS/HER) birth country in any way. The sight verification was completed via (insert document details here)",
        "value4": "The information listed on the SF86 is correct. SUBJECT maintains dual citizenship with the U.S. and (NAME OF COUNTRY) because XXXX. SUBJECT (does OR does not) take advantage or maintain any benefits or loyalties towards the foreign country which he/she holds citizenship with. Unless otherwise documented, SUBJECT does not take advantage of benefits or maintain any loyalties towards the foreign country in which SUBJECT holds citizenship. The sight verification was completed via (insert document details here)",
        "value5": "The information listed on the SF86 is correct. SUBJECT (has OR had) a foreign passport with (NAME OF COUNTRY) because XXXX. The foreign passport was issued on XX/XX/XXX and (expired on XX/XX/XXX OR is not expired). SUBJECT (does OR does not) intend to renew (his/her) foreign passport. SUBJECT (does OR does not) take advantage of benefits associated with this foreign passport. The sight verification was completed via (insert document details here)"
      },
      {
        "value1": "Report SUBJECT’s response to the question asking if anyone would question SUBJECT’s loyalty to the United States. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "There is no reason to question SUBJECT’s loyalty to the United States."
      },
      {
        "value1": "Report any positive responses to the counterintelligence/counterterrorism questions along with details and applicable issue resolution. If SUBJECT responded No to all questions, report a brief disclaimer as listed below. Questions can be found on the second to last page of the ESI Job Aid in ForeSite. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "SUBJECT has never been involved in, or advocated for, the use of violence or force to overthrow the United States government. SUBJECT has never engaged in any acts of terrorism or activities designed to overthrow the United States government."
      },
      {
        "value1": "Report SUBJECT’s response to the question asking if anyone would question SUBJECT’s ethical behavior, judgment, or discretion to the United States. Report the applicable disclaimer from below and adjust each disclaimer as needed to represent your Subject’s answers.",
        "value2": "No one would question SUBJECT’s ethical behavior, judgement, or discretion."
      } 
    ];

    function generateTooltips() {
      $(".otherInfo .form-group").each(function(index) {
          const textarea = $(this).find('textarea');
          if (textarea.length) {
              const textareaIndex = index;
              const tooltipClasses = ['tooltip-left', 'tooltip-center', 'tooltip-right'];
              const tooltipClass = tooltipClasses[index % 3];
              const tooltipHTML = `
                  <span class="tooltip-icon">
                      <span class="icon">i</span>
                      <span class="tooltiptext ${tooltipClass}">
                        <span class="closeIcon" style="float: right;">x</span>
                      </span>
                  </span>
              `;
              
              const label = $(this).find('label');
              if (label.length) {
                  label.append(tooltipHTML); // Append tooltip inside the label tag
                  
                  const tooltipTextContainer = label.find('.tooltiptext');
  
                  // Get the text above tooltip and add as <h3> inside tooltiptext
                  const labelText = label.find('span:first').contents().filter(function() {
                      return this.nodeType === 3; // Node type 3 refers to text nodes
                  }).text().trim();
  
                  if (labelText) {
                      tooltipTextContainer.append(`<h3>${labelText}</h3>`);
                  }
  
                  if (data[textareaIndex]) {
                      const selectedValues = data[textareaIndex];
  
                      Object.keys(selectedValues).forEach(function(key) {
                          const value = selectedValues[key];
                          if (value !== "") { // Only create checkbox if value is not an empty string
                              const checkboxHTML = `
                                  <label>
                                      <input type="checkbox" value="${value}" class="checkbox" data-textarea="${textareaIndex}"> ${value}
                                  </label><br>
                              `;
                              tooltipTextContainer.append(checkboxHTML);
                          }
                      });
                  }
              }
          }
      });
  }

  var selectedText = {};

  $(document).on("click", ".tooltip-icon", function(e) {
    if(e.target.className.includes('closeIcon')) {
      e.stopPropagation();
      e.preventDefault();
      e.currentTarget.classList.toggle('visible')
    }
  });

  $(document).on("change", ".checkbox", function(e) {
    e.stopPropagation();
    e.preventDefault();
    
    const value = $(this).val();
    const textareaIndex = $(this).data("textarea");

    /*if (!selectedText[textareaIndex]) {
        selectedText[textareaIndex] = [];
    }*/
    selectedText[textareaIndex] = [];

    if ($(this).is(":checked")) {
      selectedText[textareaIndex].push(value);
      /*
        // commenting since we want to append regardless of already existing or not
        if (!selectedText[textareaIndex].includes(value)) {
            selectedText[textareaIndex].push(value);
        }*/
    } /*
    // commenting since we dont want to remove regardless of already existing or not
    else {
        const index = selectedText[textareaIndex].indexOf(value);
        if (index > -1) {
            selectedText[textareaIndex].splice(index, 1);
        }
    }*/

    const adjacentTextarea = $(this).closest('.form-group').find('textarea');

    if (adjacentTextarea.length) {
        const manualText = adjacentTextarea.val().trim();
        const selectedValues = selectedText[textareaIndex].join("\n\n");
        const combinedText = [manualText, selectedValues].filter(Boolean).join("\n\n");
        selectedText[textareaIndex] = [manualText, selectedValues];
        adjacentTextarea.val(combinedText);
        adjacentTextarea.css("height", "250px");
        adjacentTextarea.scrollTop(adjacentTextarea[0].scrollHeight);
    }
});

  generateTooltips();
});
