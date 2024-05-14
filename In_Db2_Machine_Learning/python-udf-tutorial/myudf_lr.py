
################
### IMPORTS ###
###############
import nzae

import pandas as pd
from joblib import load

ml_model_path = '/home/shaikhq/pipe_lr/pipe_lr.joblib'
ml_model_features = ['YEAR', 'QUARTER', 'MONTH', 'DAYOFMONTH', 'DAYOFWEEK', 'UNIQUECARRIER', 'ORIGIN', 'DEST', 'CRSDEPTIME', 'DEPDELAY', 'DEPDEL15', 'TAXIOUT', 'WHEELSOFF', 'CRSARRTIME', 'CRSELAPSEDTIME', 'AIRTIME', 'DISTANCEGROUP']

class full_pipeline(nzae.Ae):
    def _runUdtf(self):
        #####################
        ### INITIALIZATON ###
        #####################
    
        trained_pipeline = load(ml_model_path)
        
        #######################
        ### DATA COLLECTION ###
        #######################
        # Collect rows into a single batch
        rownum = 0
        row_list = []
        for row in self:
            if (rownum==0):
                # Grab batchsize from first element value (select count (*))
                batchsize=row[0] 
            
            # Collect everything but first element (which is select count(*))
            row_list.append(row[1:])
            rownum = rownum+1
            if rownum==batchsize:
                ##############################
                ### MODEL SCORING & OUTPUT ###
                ##############################
                
                # Collect data into a Pandas dataframe for scoring
                data=pd.DataFrame(row_list,columns=ml_model_features)
                
                # Call our trained pipeline to transform the data and make predictions
                predictions = trained_pipeline.predict(data)
                
                # Output the columns along with the corresponding prediction
                for x in range(predictions.shape[0]):
                    outputs = []
                    for i in row_list[x]:
                        outputs.append(i)
                    if predictions.dtype.kind=='i':
                        outputs.append(int(predictions[x]))
                    else:
                        outputs.append(float(predictions[x]))
                    self.output(outputs)

                #Reset rownum and row_list for next batch
                row_list=[]
                rownum=0
        self.done()
full_pipeline.run()
    