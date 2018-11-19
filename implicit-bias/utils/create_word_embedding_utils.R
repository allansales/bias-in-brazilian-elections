library(readr)
library(wordVectors)
library(rword2vec)
library(dplyr)
library(stringr)

# analogias <- c("pt psdb dilma", "pt pv dilma","pt prtb dilma","pt psol dilma","pt psb dilma","pt psdc dilma","psdb pv aécio","psdb prtb aécio","psdb psol aécio","psdb psb aécio","psdb psdc aécio","pv prtb jorge","pv psol jorge","pv psb jorge","pv psdc jorge","prtb psol fidelix","prtb psb fidelix","prtb psdc fidelix","psol psb luciana","psol psdc luciana","psb psdc marina","dilma aécio rousseff","campos psb aécio","pt psdb petista")
# respostas <- c("aécio","jorge","fidelix","luciana","marina","eymael","jorge","fidelix","luciana","marina","eymael","fidelix","luciana","marina","eymael","luciana","marina","eymael","marina","eymael","eymael","neves","psdb","tucano")

cria_word_embedding <- function(tema, n_layers = 300, analogias, respostas, noticias, texto_col, path_saida){
  
  train_file = paste(path_saida,tema,".csv",sep="")
  binary_file = paste(path_saida,tema,".bin",sep="")
  noticias %>% select_(texto_col) %>% write_csv(train_file)
  modelo <- train_word2vec(train_file, threads = 8, vectors = n_layers)
  
  ### Regras que devem ser acertadas para validar embedding
  if(!is.null(analogias)){
    analogias = verifica_analogias(binary_file, analogias, respostas)  
  }
  
  file.remove(train_file)
  
  return(list(modelo = modelo, analogias = analogias))
}

cria_word_embedding_on_csv <- function(csv_name, complemento, analogias, respostas, n_layers = 300){
  
  rename_binary_file = function(binary_file, new_named_binary_file){
    file.rename(binary_file, new_named_binary_file)
  }
  
  modelo = train_word2vec(csv_name, threads = 8, vectors = n_layers)
  
  binary_file_name = str_replace(csv_name, ".csv", ".bin")
  ### Regras que devem ser acertadas para validar embedding
  if(!is.null(analogias)){
    analogias = verifica_analogias(binary_file_name, analogias, respostas)  
  }
  
  new_name = str_replace(csv_name, ".csv", "") %>% paste("_",complemento,".bin",sep="")
  rename_binary_file(binary_file_name, new_name)
  
  return(list(modelo = modelo, analogias = analogias))
}

verifica_analogias <- function(bin_path, analogias, respostas){
  # Verifica se a saida esperada de uma analogia corresponde a saida que o algoritmo esta retornando
  # TRUE se a saida esperada eh igual ao do algoritmo, FALSE caso contrario
  word2vec_resposta <- function(binary_file, analogia, saida_esperada){
    word_analogy(file_name = binary_file, search_words = analogia) %>% 
      slice(1) %>% 
      select(word) %>% 
      .[[1]] %>% 
      as.character()
  }
  
  analogia_resposta <- data_frame(analogia = analogias, resposta_esperada = respostas) %>% rowwise() %>% 
    mutate(w2v_resposta = word2vec_resposta(bin_path, analogia, resposta_esperada), acertos = (resposta_esperada == w2v_resposta))
  
  acuracia <- analogia_resposta %>%
    count(acertos) %>%
    mutate(freq = n / sum(n)) %>% 
    filter(acertos == T) %>% select(freq) %>%
    as.numeric()
  
  return(list(analogia_resposta = analogia_resposta, acuracia = acuracia))
}