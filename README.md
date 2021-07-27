# Azure-Cognitive-Services
Delphi Classes and Samples for connecting to, and using, Azure Cognitive Services

## Overview
The classes make it simple to use the following Microsoft Azure Cloud services:
### Translator
* Text Translation (converting text from one to multiple languages)
* Dictionary Look up (looking up a words between languages and reporting on its usage)
### Speech
* Text To Speech (converting text using one, or multiple voices into audio file)
* Speech to Text (converting .wav or .ogg files to text)

In the source directory you will find units following the convension of Azure.API3.<service>.<method>
  
## Example/Sample
The Samples folder includes an example written in Delphi (tested on 10.4.2).
Each part of the functionality is delivered via seperate frames. 
To help with the testing and evaluation, the sample has a menu to save / auto load your API Key and Region once you have added them when running.
The sample also includes audio.wav that you can use to see the SpeechToText methods working.

## Prerequisite
Azure Cognitive Services are grouped into different capabilities/services that are accessed via instances with access keys.
  
To use these classes you need to first get an Azure Cognitive Services subscription for the  
You can get a free account for accessing the Azure portal at https://azure.microsoft.com/

Once you have logged into the Azure Portal, you need to "create a resource" for 
  * Translator 
  * Speech
  
For each Azure resource, select it from the home page and then:
  * Got to "Keys and Endpoints"
  * Copy Key 1 or Key 2
  * Make note of the Location/Region
  * Run the app, and add the Key & set the region for the Service (and then choose Save from the menu if you want to avoid adding it next time you run)
  
If you don't have RAD Studio/Delphi you can download the trial from https://www.embarcadero.com/products/rad-studio/ or the community edition from  https://www.embarcadero.com/products/delphi/starter/free-download 
  
