import nzae
import llama_cpp

class EMBEDDING(nzae.Ae):

    modelDir = "$EMBEDDING_MODEL_DIR/"
    outPrec = 7

    def _runUdf(self):
        for row in self:
            model, prompt = row
            embedding = self.getEmbedding(model, prompt)
            self.output(self.embeddingToStr(embedding,self.outPrec))
        self.done()

    def getEmbedding(self, model, prompt):
        model = self.modelDir + model
        llm = llama_cpp.Llama(model_path=model, embedding=True)
        embedding = llm.create_embedding(prompt)
        return embedding["data"][0]["embedding"]

    def embeddingToStr(self, embedding, precision):
        eStrings = [f'{e:.{precision}f}' for e in embedding]
        return ', '.join(eStrings)

EMBEDDING.run()
