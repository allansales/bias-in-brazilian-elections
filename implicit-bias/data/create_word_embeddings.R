source("../utils/create_word_embedding_utils.R")

args = commandArgs(TRUE)
csv_name = as.character(args[1])
num_iter = as.integer(args[2])
analogias_file = read_csv(as.character(args[3]))

# csv_name = "./2018/noticias_carta/noticias_eleicao_carta.csv"
# num_iter = 15
# analogias_file = "./2018/analogias"
# analogias_file = read_csv(analogias_file)

analogias = analogias_file$analogia
respostas = analogias_file$resposta

embeddings_config_name = csv_name %>% str_replace(".csv","") %>% paste("_config",".csv",sep="")
embeddings_config = data_frame()
for(i in 1:num_iter){
  we = cria_word_embedding_on_csv(csv_name, i, analogias, respostas)
  we_config = cbind(we$analogias$analogia_resposta, acc = we$analogias$acuracia, id = i)
  embeddings_config = embeddings_config %>% rbind(we_config)
  write_csv(embeddings_config, embeddings_config_name)
  
  rm(we)
  gc(TRUE)
}
