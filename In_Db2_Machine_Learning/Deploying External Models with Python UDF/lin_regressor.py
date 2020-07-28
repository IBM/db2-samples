import nzae
from joblib import load

class predict_price(nzae.Ae):
    def _setup(self):
        self.model = load('/home/test/external_model.joblib')

    def predict(self,data):
        result = self.model.predict([data])
        return float(result[0])

    def _getFunctionResult(self,row):
        price = self.predict(row)
        return price

predict_price.run()

