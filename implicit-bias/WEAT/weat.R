library("readr")
library("wordVectors")
library("partitions")
library("gtools")
library("purrr")
library("perm")
library("text2vec")
library("tidytext")
library("combinat")

library("doParallel")
library("foreach")

library("dplyr")

library("tm")

cosSim_model <- function(w1, w2, modelo){
  cosineSimilarity(modelo[[w1]],modelo[[w2]]) %>% as.numeric()
}

create_pares <- function(x, y=NULL, a, b, modelo){
  
  targets = x  
  if(!is.null(y)){
    targets = c(x, y)  
  }
  
  features = c(a, b)
  
  pares = expand.grid(target = targets, feature = features)
  
  pares$target = pares$target %>% as.character()
  pares$feature = pares$feature %>% as.character()
  
  pares = pares %>%
    rowwise() %>%
    mutate(cos_sim = cosSim_model(target, feature, modelo))
  
  targets_a = pares %>% filter(feature %in% a)
  targets_b = pares %>% filter(feature %in% b)
  return(list(targets_a = targets_a, targets_b = targets_b))
}

create_cosine_metrics <- function(targets_a, targets_b){ #tabela de diferenca de similaridades das palavras alvo para os conjuntos a e b

  w_sim_a = targets_a %>% group_by(target) %>% summarise(mean_cos = mean(cos_sim)) %>% arrange(target)
  w_sim_b = targets_b %>% group_by(target) %>% summarise(mean_cos = mean(cos_sim)) %>% arrange(target)

  w_dif_a_b = bind_cols(w_sim_a %>% select(target), #poderia usar w_sim_b. as duas terao a mesma ordem
                        (w_sim_a %>% select(mean_cos) -
                           w_sim_b %>% select(mean_cos)))

  w_dif_a_b = w_dif_a_b %>% rename(dif = mean_cos)

  return(w_dif_a_b)
}


permutacao <- function(x, y){
  
  all_targets = c(x,y)
  n = length(all_targets)
  Xi = combinat::combn(all_targets, n/2) %>% t() %>% as.data.frame()
  colnames(Xi) = paste("X",colnames(Xi),sep = "")

  Yi = Xi %>% apply(1, FUN=function(x){
    setdiff(all_targets, x)
  }) %>% t() %>% as.data.frame()
  colnames(Yi) = paste("Y",colnames(Yi),sep = "")
  
  return(list(Xi = Xi, Yi = Yi))
}

effect_size <- function(x, y, dif_sim_table){
  
  x_mean = dif_sim_table %>% filter(target %in% x) %>% summarise(mean_dif = mean(dif)) %>% as.numeric()
  y_mean = dif_sim_table %>% filter(target %in% y) %>% summarise(mean_dif = mean(dif)) %>% as.numeric()
  
  w_sd = dif_sim_table %>% summarise(sd = sd(dif)) %>% as.numeric()
  
  return((x_mean - y_mean)/w_sd)
}

wefat <- function(dif_sim_table, w_cos_dist){
  
  dif_sim_table = dif_sim_table %>% arrange(target)
  w_sd = w_cos_dist %>% group_by(target) %>% summarise(sd = sd(cos_sim)) %>% arrange(target)
  
  w_wefat = bind_cols(dif_sim_table %>% select(target),
                      dif_sim_table %>% select(dif)/
                      w_sd %>% select(sd))
  
  return(w_wefat)
}

vies_entidade <- function(pares){
  dif_sim_table = create_cosine_metrics(pares$targets_a, pares$targets_b)
  bias_entity = sum(dif_sim_table$dif)
  return(data_frame(bias_entity))
}

execute_weat <- function(x, y, targets_a, targets_b){
  
  dif_sim_table = create_cosine_metrics(targets_a, targets_b)
  p_test = permutation_test(dif_sim_table, x, y)
  
  p_valor = p_test$p.value
  score_x_y = p_test$estatistica
  
  tam_efeito = effect_size(x, y, dif_sim_table)

  valores = data_frame(p_valor, tam_efeito)
  return(valores = valores)
}

execute_weat_wmd_2 <- function(we, x, y, a, b){
  dif_sim_table = get_dif_wmd_table(we, x, y, a, b)
  p_test = permutation_test(dif_sim_table, x, y)
  
  p_valor = p_test$p.value
  score_x_y = p_test$estatistica
  
  tam_efeito = effect_size(x, y, dif_sim_table)
  
  valores = data_frame(p_valor, tam_efeito)
  return(valores = valores)
}

permutation_test <- function(dif_sim_table, x, y){
  xi = dif_sim_table %>% filter(target %in% x)
  yi = dif_sim_table %>% filter(target %in% y)
  
  permtest = permTS(xi$dif, yi$dif, alternative = "two.sided")
  return(list(p.value = permtest$p.value, estatistica = permtest$statistic))
}

## Escolhe palavras para definir um conjunto
get_palavras_proximas <- function(alvo, sim_boundary, word_embedding){
  # 200 poderia ser qualquer numero. foi escolhido apenas para garantir que teriamos muitas palavras a ser filtradas
  words = closest_to(word_embedding, word_embedding[[alvo]], 200)
  colnames(words)[2] = "similarity"
  words = words %>% filter(similarity >= sim_boundary)
  return(words)
}

execute_weat_wmd <- function(we, x, y, a, b){

  makeSparseDTM = function(dtm){
    dtm.sparse <- Matrix::sparseMatrix(i=dtm$i, j=dtm$j, x=dtm$v, dims=c(dtm$nrow, dtm$ncol))
    rownames(dtm.sparse) <- tm::Docs(dtm)
    colnames(dtm.sparse) <- tm::Terms(dtm)
    return(dtm.sparse)
  }
    
  perm_to_sparse_matrix = function(perms, a, b){
    perms = perms %>% slice(1:(n()/2))
    
    perms_ = perms %>% group_by_all() %>%
      do(data_frame(doc = paste(mutate_all(., as.character), collapse = " ")))

    perms = perms %>% left_join(perms_)

    a = paste(a, collapse = " ")
    b = paste(b, collapse = " ")
    doc = perms$doc

    doc = c(a, b, doc)

    corpus = Corpus(VectorSource(doc))
    dtm = DocumentTermMatrix(corpus)
    sparse_matrix = makeSparseDTM(dtm)
    
    return(sparse_matrix)
  }
  
  get_wmd_for_each_feature_set = function(we, sparse_matrix, a, b){
    features=sparse_matrix[1:2,]
    targets=sparse_matrix[3:(nrow(sparse_matrix)),]
    
    rwmd = RelaxedWordMoversDistance$new(we, normalize = FALSE, progressbar = F)
    wmd = rwmd$dist2(targets, features)
    return(wmd)
  }
  
  #get value of every permutation test using wmd as metric for weat
  get_permutations_values = function(wmd_Xi, wmd_Yi){
    dif_Xi = (wmd_Xi[,1] - wmd_Xi[,2])
    dif_Yi = (wmd_Yi[,1] - wmd_Yi[,2])
    weat_value = dif_Xi - dif_Yi
    return(weat_value)
  }
  
  perms = permutacao(x, y)
  sparse_perms_Xi = perm_to_sparse_matrix(perms$Xi, a, b)
  sparse_perms_Yi = perm_to_sparse_matrix(perms$Yi, a, b)

  wmd_Xi = get_wmd_for_each_feature_set(we, sparse_perms_Xi, a, b)
  wmd_Yi = get_wmd_for_each_feature_set(we, sparse_perms_Yi, a, b)
  
  permutation_values = get_permutations_values(wmd_Xi, wmd_Yi)
  
  p_valor = sum(permutation_values >= abs(permutation_values[1]))/length(permutation_values)
  # adicinar effect size
  return(data_frame(p_valor, tam_efeito = c(NA)))
}

wmd_calculation_2 <- function(we, x, a, b){
  
  get_dif_wmd_table <- function(we, x, y, a, b){
    weat_wmd_x = wmd_calculation_2(we, x, a, b)
    weat_wmd_y = wmd_calculation_2(we, y, a, b)
    dif_table = bind_rows(weat_wmd_x, weat_wmd_y)
    return(dif_table)
  }
  
  to_dtm = function(x, a, b){
    
    format_vectors = function(vec, doc_label){
      vec = vec %>% as_data_frame() %>% rename(term = value)
      vec$count = 1
      vec$document = doc_label
      return(vec)
    }
    
    docs_x = data_frame()
    n = length(x)
    for(i in 1:n){
      doc = format_vectors(x[i],i)
      docs_x = rbind(docs_x, doc)
    }
    
    doc_a = format_vectors(a, nrow(docs_x)+1)
    doc_b = format_vectors(b, nrow(docs_x)+2)  
    dtm = bind_rows(docs_x, doc_a, doc_b) %>% cast_sparse(document, term, count)
    return(dtm)
  }
  
  dtm = to_dtm(x, a, b)
  n = nrow(dtm)
  targets=dtm[1:(n-2),]
  features=dtm[(n-1):n,]
  
  rwmd = RelaxedWordMoversDistance$new(we, normalize = TRUE, progressbar = F)
  wmd = rwmd$dist2(targets, features) %>% 
    as_data_frame() %>%
    mutate(target = x, dif = V1 - V2) %>%
    select(target, dif)
  return(wmd)
}

cria_conjunto_generico_unico_alvo = function(we, atributo_1, atributo_2, we_generico, min_atributos){
  if(length(atributo_1)==1 && length(atributo_2)==1){ # se os parametros tem tamanho 1, procure palavras para compor os conjuntos
    conjuntos_atributo = conjuntos_genericos(we_generico, we, atributo_1, atributo_2, min_atributos)
    a = conjuntos_atributo$a
    b = conjuntos_atributo$b
  } else {
    a = atributo_1
    b = atributo_2
  }
  return(data_frame(seed_a = atributo_1, seed_b = atributo_2, palavras_a=list(a), palavras_b=list(b)))
}

cria_conjunto_generico_multiplos_alvos = function(lista_de_alvos, atributo_1, atributo_2, we_generico, min_atributos){
  
  listas_palavras = lapply(lista_de_alvos, cria_conjunto_generico_unico_alvo, atributo_1, atributo_2, we_generico, min_atributos)
  
  n_wes = length(lista_de_alvos)
  palavras = bind_rows(listas_palavras)
  
  palavras_a = palavras %>% select(palavras_a) %>% unlist() %>% table() %>% as.data.frame() %>% filter(Freq == n_wes) %>% distinct()
  palavras_b = palavras %>% select(palavras_b) %>% unlist() %>% table() %>% as.data.frame() %>% filter(Freq == n_wes) %>% distinct()
  palavras = conjuntos_mesmo_tamanho(list(palavras_a$., palavras_b$.))
  palavras_a = palavras[[1]] %>% as.character()
  palavras_b = palavras[[2]] %>% as.character()
  
  return(data_frame(seed_a = atributo_1, seed_b = atributo_2, palavras_a = list(palavras_a), palavras_b = list(palavras_b)))
}

automatic_weat = function(x, y, a, b, we, metodo){
  out <- tryCatch({
    if(metodo == "weat"){
      pares = create_pares(x, y, a, b, we)
      vies = execute_weat(x, y, pares$targets_a, pares$targets_b)
    }
    
    if(metodo == "wmd"){
      vies = execute_weat_wmd(we, x, y, a, b)
    }
    return(vies)
  }, error=function(cond) {
    vies = data_frame(p_valor = c(NA), tam_efeito = c(NA))
    return(vies)
  })
  return(out)
}

automatic_vies_entidade = function(x, a, b, we){
  out <- tryCatch({
    pares = create_pares(x, a=a, b=b, modelo = we)
    vies = vies_entidade(pares)
    return(vies)
  }, error=function(cond) {
    vies = data_frame(p_valor = c(NA), tam_efeito = c(NA))
    return(vies)
  })
  return(out)
}

cria_tabela_vieses = function(target_1, target_2, tabela_atributos, we, metodo){
  scores_a = tabela_atributos %>% rowwise() %>% do(automatic_vies_entidade(target_1, .$palavras_a, .$palavras_b, we))
  scores_b = tabela_atributos %>% rowwise() %>% do(automatic_vies_entidade(target_2, .$palavras_a, .$palavras_b, we))
  
  vieses = tabela_atributos %>% rowwise() %>% do(automatic_weat(target_1, target_2, .$palavras_a, .$palavras_b, we, metodo))
  vieses = bind_cols(tabela_atributos, vieses, statistic_a = scores_a, statistic_b = scores_b)
  vieses = vieses %>% mutate(seed_x = target_1[1], seed_y = target_2[1]) #[1] o mais proximo a uma palavra eh ela mesma
  return(vieses)
}

words_in_we = function(words, we){
  we_words = attr(we@.Data, "dimnames")[[1]]
  return(words[words %in% we_words])
}

create_entidades_target <- function(noticias, target_1, target_2, we){
  
  entidade_1 = cria_conjunto_de_entidade(target_1, noticias, campo, min_entidades, we = we)
  entidade_2 = cria_conjunto_de_entidade(target_2, noticias, campo, min_entidades, we = we)
  
  conjuntos_folha = conjuntos_mesmo_tamanho(list(entidade_1$word, entidade_2$word))
  entidade_1 = conjuntos_folha[[1]]
  entidade_2 = conjuntos_folha[[2]]
  
  return(list(entidade_1 = entidade_1, entidade_2 = entidade_2))
}

run_bias <- function(entidade_1, entidade_2, we, metodo, palavras_atributos){
  
  vieses = cria_tabela_vieses(entidade_1, entidade_2, palavras_atributos, we = we, metodo)
  vieses$palavras_a = lapply(vieses$palavras_a, paste, collapse = " ") %>% unlist()
  vieses$palavras_b = lapply(vieses$palavras_b, paste, collapse = " ") %>% unlist()
  
  return(vieses)
}

arranje_entidades_target <- function(x, y, noticias, we){
  entidades = create_entidades_target(noticias, x, y, we)
  entidade_1 = entidades$entidade_1
  entidade_2 = entidades$entidade_2
  cbind(entidade_1, entidade_2) %>% as_data_frame() %>% write_csv(paste('biases/',x,'_',y,'_targets','.csv', sep=""))
  return(list(x = entidade_1, y = entidade_2))
}