"""
Sample Materials, provided under license.
Licensed Materials - Property of IBM
© Copyright IBM Corp. 2019. All Rights Reserved.
US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
"""
import pandas as pd
import numpy as np
import datetime
from dateutil.relativedelta import relativedelta
import sys
import json
import os

class CustomerSegmentationPrep():

    def __init__(self, train_or_score, 
        granularity_key='CUSTOMER_CUSTOMER_ID',
        customer_start_date='CUSTOMER_SUMMARY_START_DATE',
        customer_end_date='CUSTOMER_SUMMARY_END_DATE',
        status_attribute='CUSTOMER_STATUS',
        status_flag_active='Active',
        date_customer_joined='CUSTOMER_RELATIONSHIP_START_DATE',
        columns_required=['CUSTOMER_CUSTOMER_ID', 'CUSTOMER_STATUS', 'CUSTOMER_SUMMARY_START_DATE', 'CUSTOMER_SUMMARY_END_DATE',
                        'CUSTOMER_EFFECTIVE_DATE',  'CUSTOMER_SYSTEM_LOAD_TIMESTAMP'], 
        default_attributes=['CUSTOMER_GENDER', 'CUSTOMER_AGE_RANGE', 'CUSTOMER_EDUCATION_LEVEL',
                                'CUSTOMER_EMPLOYMENT_STATUS', 'CUSTOMER_MARITAL_STATUS', 'CUSTOMER_NUMBER_OF_DEPENDENT_CHILDREN',
                                'CUSTOMER_URBAN_CODE', 'CUSTOMER_ANNUAL_INCOME', 'CUSTOMER_RELATIONSHIP_START_DATE',
                                'CUSTOMER_SUMMARY_FUNDS_UNDER_MANAGEMENT', 'CUSTOMER_SUMMARY_RETURN_SINCE_INCEPTION',
                                'CUSTOMER_SUMMARY_RETURN_LAST_QUARTER', 'CUSTOMER_SUMMARY_ASSETS',
                                'CUSTOMER_SUMMARY_NUMBER_OF_ACTIVE_ACCOUNTS', 'CUSTOMER_SUMMARY_NUMBER_OF_EMAILS',
                                'CUSTOMER_SUMMARY_NUMBER_OF_LOGINS', 'CUSTOMER_SUMMARY_NUMBER_OF_CALLS',
                                'CUSTOMER_SUMMARY_TOTAL_NUMBER_OF_BUY_TRADES', 'CUSTOMER_SUMMARY_TOTAL_NUMBER_OF_SELL_TRADES',
                                'CUSTOMER_SUMMARY_TOTAL_AMOUNT_OF_ALL_FEES'] , 
        risk_tolerance_list = [], investment_objective_list = [], effective_date = '2018-09-30', std_multiplier=5, max_num_cat_cardinality=10,
        nulls_threshold=0.1):
            
        self.train_or_score = train_or_score
        self.columns_required = columns_required
        self.default_attributes = default_attributes 
        self.granularity_key = granularity_key
        self.date_customer_joined = date_customer_joined 
        self.customer_end_date = customer_end_date  
        self.customer_start_date = customer_start_date 
        self.risk_tolerance_list = risk_tolerance_list
        self.investment_objective_list = investment_objective_list 
        self.effective_date = effective_date
        self.status_attribute = status_attribute
        self.status_flag_active = status_flag_active
        self.std_multiplier = std_multiplier
        self.max_num_cat_cardinality = max_num_cat_cardinality
        self.nulls_threshold = nulls_threshold

        # if effective date is a date convert it to a string for consistency
        if isinstance(self.effective_date, datetime.datetime):
            self.effective_date = datetime.datetime.strftime(self.effective_date, '%Y-%m-%d')
            
        if self.train_or_score == 'train':
            # create a dictionary with all values for user inputs. We will save this out and use it for scoring
            # to ensure that the user inputs are consistent across train and score notebooks
            # exclude variables that won't be used for scoring
            self.user_inputs_dict = { 'columns_required' : columns_required, 'default_attributes' : default_attributes,
                'granularity_key' : granularity_key, 'date_customer_joined' : date_customer_joined, 
                'customer_end_date' : customer_end_date, 'customer_start_date' : customer_start_date,
                'risk_tolerance_list' : risk_tolerance_list, 'investment_objective_list' : investment_objective_list,
                'effective_date' : effective_date, 'status_attribute' : status_attribute,
                'status_flag_active' : status_flag_active, 'std_multiplier' : std_multiplier,
                'max_num_cat_cardinality' : max_num_cat_cardinality, 'nulls_threshold' : nulls_threshold }

    # function to get the difference between 2 dates returned in months
    def udf_n_months(self, date1, date2):
        month_dif = (relativedelta(date1, date2).months + 
                relativedelta(date1, date2).years * 12)
        return month_dif

    # function to fill in any missing data for customer join date
    # if only some records are missing for the customer and we have the join date in other records use that
    # Otherwise, use the earliest customer summary start date
    def fill_date_customer_joined(self, df):
        nb_cust_date_customer_joined_filled = df[df[self.date_customer_joined].isnull()][self.granularity_key].nunique()

        if nb_cust_date_customer_joined_filled > 0:
            print('Filling date_customer_joined for ' + str(nb_cust_date_customer_joined_filled) + ' customers')
            # get a list of the customers who are missing start dates
            cust_date_cust_joined_missing = list(df[df[self.date_customer_joined].isnull()][self.granularity_key].unique())

            # check to see if any of the start date records for the customer are filled in
            # use this if it's available
            df_new_start_date = df[df[self.granularity_key].isin(cust_date_cust_joined_missing)].groupby(self.granularity_key)[self.date_customer_joined].min().reset_index()
            df_new_start_date = df_new_start_date[df_new_start_date[self.date_customer_joined].notnull()]
            df_new_start_date.rename(columns={self.date_customer_joined: 'MIN_START_DATE'}, inplace=True)
            if df_new_start_date.shape[0] > 0:
                df = df.merge(df_new_start_date, on=self.granularity_key, how='left')
                df[self.date_customer_joined].fillna(df['MIN_START_DATE'], inplace=True)
                # since these customers are not now missing start dates, remove them from the list
                cust_date_cust_joined_missing = list(set(cust_date_cust_joined_missing) - set(df_new_start_date[self.granularity_key].unique()))
                # drop the min_start_date var
                df.drop('MIN_START_DATE', axis=1, inplace=True)

            if len(cust_date_cust_joined_missing) > 0:
                # get the earliest customer summary start date for each customer who is missing a start date
                df_new_start_date = df[df[self.granularity_key].isin(cust_date_cust_joined_missing)].groupby(self.granularity_key)[self.customer_start_date].min().reset_index()
                df_new_start_date.rename(columns={self.customer_start_date:'NEW_START_DATE'}, inplace=True)
                # join back to original df and update 
                df = df.merge(df_new_start_date, on=self.granularity_key, how='left')
                df[self.date_customer_joined].fillna(df['NEW_START_DATE'], inplace=True)
                df.drop('NEW_START_DATE', axis=1, inplace=True)

        return df

    # this function returns a list of dynamic attributes from lists provided
    # User provides a list of risk and investment objective types
    # the function gets the column names for the counts of accounts of each type
    def dynamic_attributes_from_list(self):
        dynamic_attributes = []
    
        if len(self.risk_tolerance_list) > 0:
            for risk in self.risk_tolerance_list:
                col_name = 'NUM_ACCOUNTS_WITH_RISK_TOLERANCE_' + risk.upper().replace(" ", "_")
                dynamic_attributes.append(col_name)
    
        if len(self.investment_objective_list) > 0:
            for objective in self.investment_objective_list:
                col_name = 'NUM_ACCOUNTS_WITH_INVESTMENT_OBJECTIVE_' + objective.upper().replace(" ", "_")
                dynamic_attributes.append(col_name)
    
        return dynamic_attributes

    # this function filters the dataframe to only include the columns that are specified
    def filter_attributes(self, df, columns_required, default_attributes):
    
        # the attributes we will use are the required ones plus ones specitied in defualt_attributes
        working_attributes = columns_required + default_attributes
        # check to make sure we don't have duplicate columns names
        working_attributes = list(set(working_attributes))
        #check to make sure that the attributes are in the original dataframe
        if set(working_attributes) - set(df.columns) == 0:
            print('Invalid column names, no column names in columns_required or default_attributes lists are contained in the dataframe')
    
        # check to see if any columns passed in the list are not actually in the dataframe, print them to screen
        # and remove from the list of working_attributes
        cols_passed_but_not_in_df = [attribute for attribute in working_attributes if attribute not in df.columns]
        if len(cols_passed_but_not_in_df) > 0:
            print(str(len(cols_passed_but_not_in_df)) + ' columns were passed but are not contained in the data. :' + str(cols_passed_but_not_in_df))
            working_attributes = [col for col in working_attributes if col not in cols_passed_but_not_in_df]
        
        df = df[working_attributes]
        return df

    # This function does some data cleaning by removing columns that have constant or missing values
    # All numeric data that has only 1 value is removed
    # For categorical variables, we drop columns that have only 1 unique value
    # For categoricals, we drop columns that have a cardinality greater than or equal to max_num_cat_cardinality
    # If drop_count_column_distinct is True, we drop columns that have null values above the specified threshold, nulls_threshold
    def drop_dataframe_columns(self, df, max_num_cat_cardinality = 10, nulls_threshold = 0.1, keep=[], drop_count_column_distinct=False):

        print('Before cleaning, we had ' + str(df.shape[1]) + ' columns.')
        # get the numeric columns
        numeric_cols = list(df.select_dtypes(include=[np.number]).columns)
        # remove the columns that are required from the list
        numeric_cols = list(set(numeric_cols) - set(keep))

        # drop all numeric columns that just contain a constant value, min=max
        # record cols that we are dropping and remove after iterating over the list
        # don't remove in list as I think it causes issues when iterating over it
        cols_to_remove = []
        for col in numeric_cols:
            curr_col = df[col]
            if curr_col.max() == curr_col.min():
                df.drop(col, axis=1, inplace=True)
                # remove the column from our list of numerical variables
                cols_to_remove.append(col)

        numeric_cols = list(set(numeric_cols) - set(cols_to_remove))

        # get the string and datetime columns
        string_cols = list(df.select_dtypes(include=[object]).columns)
        # remove the columns that are required from the list
        string_cols = list(set(string_cols) - set(keep))
        datetime_cols = list(df.select_dtypes(include=[np.datetime64]).columns)
        # remove the columns that are required from the list
        datetime_cols = list(set(datetime_cols) - set(keep))

        # treat string and datetime cols the same for below
        not_num_cols = string_cols + datetime_cols

        # get a count of number of null values in each column,
        # if the number of nulls is greater than a threshold percentage, drop the column
        if drop_count_column_distinct:
            cols_to_remove = []
            for col in numeric_cols:
                curr_col = df[col]
                if (curr_col.isna().sum()/curr_col.shape[0]) > nulls_threshold:
                    df.drop(col, axis=1, inplace=True)
                    # add the column name to the list of attributes to remove
                    cols_to_remove.append(col)

            numeric_cols = list(set(numeric_cols) - set(cols_to_remove))  

            # do the same for non-numerical columns
            cols_to_remove = []
            for col in not_num_cols:
                curr_col = df[col]
                if (curr_col.isna().sum()/curr_col.shape[0]) > nulls_threshold:
                    df.drop(col, axis=1, inplace=True)
                    # add the column name to the list of tho
                    cols_to_remove.append(col)

            numeric_cols = list(set(not_num_cols) - set(cols_to_remove))  

        # drop categorical variables that are constant or more than cat_cardinality_threshold (10) categories
        for col in string_cols:
            col_cardinality = df[col].nunique()
            if col_cardinality == 1 or col_cardinality >= max_num_cat_cardinality:
                df.drop(col, axis=1, inplace=True)

        print('After cleaning, we have ' + str(df.shape[1]) + ' columns.')

        return df

    # This function takes a dataframe, a list of columns and a multiplier
    # and replaces values that are more than multiplier * standard deviations from the mean
    def clean_outliers(self, df, column_list, multiplier=5):
        for col in column_list:
            col_std = df[col].std()
            col_mean = df[col].mean()
            df.loc[df[col] >= col_mean + (multiplier * col_std), col] = col_mean + (multiplier * col_std)

        return df

    def prep_data(self, df_raw, train_or_score):
        # just in case any caps are used
        train_or_score = train_or_score.lower()

        # find the columns that are used for risk and investment objective
        dynamic_attributes = self.dynamic_attributes_from_list()
        # add the dynamic attributes to the already defined default attribute list
        self.default_attributes = self.default_attributes + dynamic_attributes

        # filter the dataframe to only include attributes that have been specified
        df_prep = self.filter_attributes(df_raw, self.columns_required, self.default_attributes)

        # fill missing customer join dates with the customer summary start date
        if self.date_customer_joined in df_prep.columns:
            df_prep = self.fill_date_customer_joined(df_prep)
        
        # filter to only include customers who most recent record is active. All customers who churned are removed
        #sort by customer ID and summary END_DATE, take the latest record
        df_prep = df_prep.sort_values(by=[self.granularity_key, self.customer_end_date])
        df_prep = df_prep.groupby(self.granularity_key).last().reset_index()

        print('Before removing inactive customers we have ' + str(df_prep[self.granularity_key].nunique()) + ' customers')
        df_prep = df_prep[df_prep[self.status_attribute]==self.status_flag_active]
        print('After removing inactive customers we have ' + str(df_prep[self.granularity_key].nunique()) + ' customers')

        # drop some columns that we don't need
        df_prep.drop(['CUSTOMER_STATUS', 'CUSTOMER_SYSTEM_LOAD_TIMESTAMP'], axis=1, inplace=True)

        if train_or_score == 'train':
            # drop more columns
            # we only do this for training, as when scoring, we already know the columns dropped from training
            df_prep = self.drop_dataframe_columns(df_prep, self.max_num_cat_cardinality, self.nulls_threshold, keep=self.columns_required, drop_count_column_distinct=True)

        # Calculate the customer tenure
        if self.date_customer_joined in df_prep.columns:
            df_prep = df_prep[df_prep[self.date_customer_joined]<=datetime.datetime.strptime(self.effective_date, '%Y-%m-%d')]
            if df_prep.shape[0] == 0:
                print('Error: No data to train with', file=sys.stderr)
            else:
                print('Add a column for customer tenure')
                df_prep['CUSTOMER_TENURE_IN_MONTHS'] = df_prep.apply(lambda x: self.udf_n_months(datetime.datetime.strptime(self.effective_date, '%Y-%m-%d'), x[self.date_customer_joined]), axis=1)        
        
        if df_prep.shape[0] == 0:
            return None
          
        # drop any column that looks like a date
        if train_or_score == 'train':
            for col in df_prep.columns:
                if df_prep[col].dtype == 'datetime64[ns]':
                    df_prep.drop(col, axis=1, inplace=True)

        print('Prepped data has ' + str(df_prep.shape[0]) + ' rows and ' + str(df_prep.shape[1]) + ' columns.')
        print('Prep has data for ' + str(df_prep[self.granularity_key].nunique()) + ' customers')
        
        if train_or_score == 'train':
            # get a list of columns that we would like to remove outliers for
            # we use only float valued columns
            float_cols = list(df_prep.select_dtypes(include=[np.float]).columns)
            # call the function to remove outliers
            df_prep = self.clean_outliers(df_prep, float_cols, self.std_multiplier) 

        # for string columns replace nulls with 'Unknown'
        # for numerical replace with mean. If there are no values for the column to calculate a mean (can happen in scoring),
        # fill with 0 instead
        string_cols = list(df_prep.select_dtypes(include=[object]).columns)
        numeric_cols = list(df_prep.select_dtypes(include=[np.number]).columns)

        for col in string_cols:
            df_prep[col].fillna('Unknown', inplace=True)

        for col in numeric_cols:
            col_mean = df_prep[col].mean()
            # if the whole column is null (can happen when scoring, esp if just 1 customer), fill the value with 0
            if pd.isnull(col_mean):
                df_prep[col].fillna(0, inplace=True)
            else:
                df_prep[col].fillna(col_mean, inplace=True)
        
        if train_or_score == 'train':
            with open('/project_data/data_asset/training_data_metadata.json', 'w') as f:
                json.dump(self.user_inputs_dict, f)
        return df_prep
