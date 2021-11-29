# Azure AdventureWorks database setup
The following instructions enable learners to prepare their Microsoft SQL AdventureWorks database lab environments suitable for GCU courses:
  MIS-605 Introduction to Databases 
  and MIS-650 Performing Analytics Using a Statistical Language


Environment setup with Azure SQL database and the AdventureWorks sample database will consist of the following steps:
- Create Azure Account (Redeem student credits)
- Provision Azure SQL Database and import the AdventureWorks database
- Install Azure Data Studio


### Redeem your Student Azure subscription credits
***Note:** These instructions are designed to be used with a [Student Azure subscription](https://azureforeducation.microsoft.com/devtools).
as a GCU student you are eligible for a 12-month Azure Subscription.*


1. Go to https://azureforeducation.microsoft.com/devtools and Sign In using your GCU username and password.

![image](https://user-images.githubusercontent.com/32605416/143666663-cbc51004-df28-4a7e-b04c-92ff5fbc392b.png)

2. Once you have Signed In to the Azure Dev Tools for Education the first time you will need to activate your Student Azure Account.

![image](https://user-images.githubusercontent.com/32605416/143666718-7e9d2774-b94f-41c5-a850-66dbee9c388b.png)

3. From this point forward, you will access your Azure subscription by logging into the [Azure Portal](https://portal.azure.com)

![image](https://user-images.githubusercontent.com/32605416/143667008-6369d876-9f7b-49c5-8d04-4a38bc16da20.png)

now that you have an Azure account you are ready to Provision your Azure environment.

### Provision your Azure Environment

1. Open a browser to https://shell.azure.com


2. Select PowerShell as the scripting language

![image](https://user-images.githubusercontent.com/32605416/143921670-87777ea5-33eb-4439-9d67-c4447beabde0.png)

3. In the Azure Shell run the following command to copy the configuration files, this may take a couple of minutes.

`git clone https://github.com/GCUMIS605/adventureworks.git`

![image](https://user-images.githubusercontent.com/32605416/143924851-4d17b57f-6fab-4370-b6ea-edbb7871fede.png)

4. In PowerShell, use the following command to change directories to the folder containing the automation scripts.

`cd ./adventureworks/scripts/`

![image](https://user-images.githubusercontent.com/32605416/143925271-2fe87cd9-aac2-48d6-97ff-59503691e764.png)

5. In PowerShell, enter the following command to run the setup script:

`.\GCUAdventureWorks.ps1`

6. When prompted to sign into Azure, and your browser opens; sign in using your credentials. After signing in, you can close the browser and return to Windows PowerShell, which should display the Azure subscriptions to which you have access.

7. When prompted, sign into your Azure account again (this is required so that the script can manage resources in your Azure subscription - be sure you use the same credentials as before).

8. If you have more than one Azure subscription, when prompted, select the one you want to use in the labs by entering its number in the list of subscriptions.

9. When prompted, enter a suitably complex password for the SQL Database (make a note of this password you will need it later).

***Note:** This script will take 15-30 minutes to complete*

### Download and Install Azure Data Studio
Azure Data Studio is a cross-platform database tool for data professionals who use on-premises and cloud data platforms on Windows, macOS, and Linux.

For download and installation instructions for Azure Data Studio, please see https://docs.microsoft.com/en-us/sql/azure-data-studio/download-azure-data-studio?view=sql-server-ver15

***Note:** You will also need the SQL Server Import extension for Azure Data Studio*

The SQL Server Import extension converts .txt and .csv files into a SQL table.  For installation instructions, please see https://docs.microsoft.com/en-us/sql/azure-data-studio/extensions/sql-server-import-extension?view=sql-server-ver15

