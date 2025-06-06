import nzae
import llama_cpp

class EMBEDDING(nzae.Ae):

    modelDir = "$EMBEDDING_MODEL_DIR/"
    batchSize = 200
    outPrec = 7

    def _runUdtf(self):
        batchSize = self.batchSize
        lastRow = 0
        modelName = ""
        promptList = []
        idList = []
        rowNum = 0
        batchRow = 0
        for row in self:
            if (rowNum==0):
                # Grab number input rows
                lastRow = row[0]
                modelName = row[1]

            promptList.append(row[2])
            idList.append(row[3])
            rowNum = rowNum+1
            batchRow = batchRow+1

            # have we reached the end of the input?
            if rowNum==lastRow:
                # handle empty batch
                if batchRow==0:
                    break
                # handle partially filled batch
                batchSize = batchRow
            
            # batch filled up? --> process it
            if batchRow==batchSize:
                embeddings = self.getEmbeddings(modelName, promptList)
                i=0
                for e in embeddings:
                    self.output(self.embeddingToStr(e["embedding"],self.outPrec), idList[i])
                    i = i+1
                # reset batchRow, promptList and idList for next batch
                promptList=[]
                idList=[]
                batchRow = 0
        self.done()

    def getEmbeddings(self, model, prompts):
        model = self.modelDir + model
        llm = llama_cpp.Llama(model_path=model, embedding=True)
        embeddings = llm.create_embedding(prompts)
        return embeddings["data"]

    def embeddingToStr(self, embedding, precision):
        eStrings = [f'{e:.{precision}f}' for e in embedding]
        return ', '.join(eStrings)

EMBEDDING.run()

