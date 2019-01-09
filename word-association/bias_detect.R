library("dplyr")

source("utils/utils.R")
source("utils/create_word_embedding_utils.R")
source("utils/create_sets.R")
source("WEAT/weat.R")

get_bias_results = function(combs, we, method, attributs){
  list_of_vectors = list(x = get(combs[1]), y = get(combs[2]))  
  run_bias(list_of_vectors$x, list_of_vectors$y, we, method, attributs)
}

#################################################
# edit this variables for run in another sets
we_wikipedia_pt = read.binary.vectors("data/wikipedia_pt/wikipedia_pt.bin")

noticias = read_csv("./data/2018/noticias_folha/noticias_eleicao_folha.csv", col_names = F)
binary_path = "./data/2018/noticias_folha/binary/"
output_1 = "candidatos_folha.csv" # candidates file output
output_2 = "partidos_folha.csv"  # parties file output
automatic_set_construction = T # get most similar words according to wikipedia to construct attribute sets
#################################################

attr_min_size = 10
results_1 = data_frame()
results_2 = data_frame()
weat = "weat"

#################################################
# word sets to define candidates and parties
## candidates 2018
haddad = c("haddad","pt","lula","petista")
bolsonaro = c("bolsonaro","jair","psl","exmilitar")
ciro = c("ciro","pdt","pedetista","gomes")
marina = c("marina","exsenadora","exministra","silva")

## parties 2018
pt = c("pt","haddad","lula","gleisi")
psl = c("psl","jair","bolsonaro","exmilitar")
pdt = c("pdt","ciro","pedetista","lupi")
rede = c("rede","sustentabilidade","marina","exsenadora")
#################################################

candidates = c("haddad", "bolsonaro", "ciro", "marina")
parties = c("pt", "psl", "pdt", "rede")

candidates_comb = combn(candidates, 2)
parties_comb = combn(parties, 2)

binaries = list.files(binary_path)
n = length(binaries)
pb <- txtProgressBar(min = 0, max = n, style = 3)
for(i in 1:n){
  binary = paste(binary_path,binaries[i],sep="")
  we = read.binary.vectors(binary)

  # feature sets definition
  if (automatic_set_construction){
    # if automatically constructing the attribute set of words, add concept words to construct the sets here
    palavras_fontes_atributos = data_frame(palavra_1 = c("péssimo", "imoral", "inaceitável", "déficit", "estagnação"),
                                         palavra_2 = c("ótimo", "moral", "aceitável", "superávit", "desenvolvimento"))
    palavras_atributos = palavras_fontes_atributos %>% rowwise() %>% do(cria_conjunto_generico_unico_alvo(we, .$palavra_1, .$palavra_2, we_wikipedia_pt, attr_min_size))
  }
  
  if (!automatic_set_construction){
    # if manually constructing the attribute set of words, add each set of words here
    pejorativos_esquerda = list(c("esquerdopata","comunista","socialista","marxista","esquerdista","sindicalista","baderneiro","petralha"))
    pejorativos_direita = list(c("fascista","racista","homofóbico","capitalista","coxinha","reaça","opressor","extremista"))
    palavras_atributos = data_frame(seed_a = "pejorativos_esquerda", seed_b = "pejorativos_direita", palavras_a = pejorativos_esquerda, palavras_b = pejorativos_direita)
  }
  
  # vieses candidatos para weat com cosseno
  candidates_bias_list = apply(candidates_comb, 2, get_bias_results, we, weat, palavras_atributos)
  results_1_weat = bind_rows(candidates_bias_list)
  results_1_weat$metodo = weat

  results_1 = bind_rows(results_1, results_1_weat)
  write_csv(results_1, paste('biases/', output_1, sep=""))
  
  # vieses partidos para weat com cosseno
  parties_bias_list = apply(parties_comb, 2, get_bias_results, we, weat, palavras_atributos)
  results_2_weat = bind_rows(parties_bias_list)
  results_2_weat$metodo = weat
  
  results_2 = bind_rows(results_2, results_2_weat)
  write_csv(results_2, paste('biases/', output_2, sep=""))
  
  setTxtProgressBar(pb, i)

  rm(we)
  gc(TRUE)
}
close(pb)
