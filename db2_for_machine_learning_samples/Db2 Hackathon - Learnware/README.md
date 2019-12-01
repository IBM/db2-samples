# Db2 Hackathon - Learnware

Our recent Db2 hackthon demonstrate the versitle powers of Db2 combined with machine learning, web development, and blochaine. Through this hackthon, we had three amazing winners that used our products in intriguing ways that we would like to showcase. One of the three winners was ***Kuro Souza***. Kuro's project was called `Learnware`. This project used open source data in order to predict student performance. The steps below will show how to re-create Kuro's work for you to try out!

Original Data Files - https://www.kaggle.com/rocki37/open-university-learning-analytics-dataset


## Upload Data Files to Db2

The first thing we need to do is upload all the data files into your Db2 instance. If you open the `learnware.ipynb`, the names of the tables for each data file is outlined in in the `table_names` list. For reference I have outline them over here as well.

1. 'STUDENT_INFO'
2. 'ASSESSMENTS'
3. 'COURSES'
4. 'VLE'
5. 'STUDENT_ASSESSMENT'
6. 'STUDENT_REGISTRATION'
7. 'STUDENT_VLE2'

**Important Note** Make sure you aquire the service credentials for your Db2 instance in order to connect to the database through the notebook

## Learnware

Once the data files have been uploaded with the correct table names, we can now use the `learnware.ipynb` notebook to create our model. As you go through the notebook, make sure to replace the `<>` with your own db2 instance service credentials.

## Special Notes

Special thanks Kuro Souza for letting us use to Db2 Hackathon project as a way to demonstrate the power the Db2 paired with AI and machine learning! 

Check you this Github repo - https://github.com/kurosouza

