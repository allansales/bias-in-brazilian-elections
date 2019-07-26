# Association Bias

Instructions to verify word association bias in text:

## Execution 

1 Create word embeddings using create_word_embedding_utils.R
	csv_name = path to csv containing text data
	num_iter = number of models to be created
	analogias_file = path to file containing analogies to be executed by each model

2 Run bias_detect.R to detect biases in text according to previously created embedding models
	noticias = path to text csv of a news portal
	binary_path = path to binary file containing word embedding models
	output_* = output of candidates and parties bias
	automatic_set_construction = TRUE for construct attribut sets automatically, FALSE otherwise

3 Run data_analysis.Rmd to verify existent biases in the texts


## Appendix
Here, we make available, in portuguese (as in the paper), the sets of words used to define each entity in the word association bias:

### Target
#### Word sets 2018

- haddad: haddad, pt, lula, petista, davila
- bolsonaro: bolsonaro, jair, psl, exmilitar, mourao
- ciro: ciro, pdt, pedetista, gomes, lupi
- marina: marina, exsenadora, exministra, rede, jorge
 
#### Word sets 2014
- dilma: dilma, rousseff, petista, pt, lula
- aecio: aécio, tucano, neves, psdb, fhc
- marina: marina, albuquerque, psb, pernambuco, campos


#### Word sets 2010
- dilma: dilma, rousseff, petista, pt, lula
- serra: serra, tucano, psdb, presidenciavel, alckmin
- marina: marina, senadora, pv, ac, pvac
 
### Attributes
Each Attribute set is automatically generated based on the similarity between its source word and Wikipedia's embeddings that are available in all news outlets embeddings. For example, if we are producing a word set for the "Terrible", we compute the most similar words to "Terrible" according to Wikipedia's embeddings and check which of them are present in all news outlets embeddings. To make sure the settings are semantically concise, we manually verify each one and remove any inconstancies.

Bellow, we present the generated sets of words.

# 2010
pessimo (terrible): mau, equivocado, adiantado, preconceituoso, infeliz, injusto, atrasado, inesperado, doloroso, absurdo, triste, incerto, violento
imoral: preconceituoso, injusto, injusta, racista, desonesto, cruel, arrogante, estupro
inaceitavel (unacceptable): injusto, injusta, inconstitucional, racista, preconceituoso, ilegal, culpada
deficit: endividamento, desemprego, esvaziamento, desconforto, estresse, agravamento, congestionamento, esgotamento, desgaste, atraso
estagnacao (stagnation): instabilidade, crise, derrocada, debilidade, estiagem, ruptura, desordem, escassez

otimo (excelent): excelente, destacado, interessante, melhor, melhorado, lindo, unico, excepcional, talentoso, inovador, bacana, impressionante, ideal
moral: honestidade, disciplina, conduta, dignidade, humildade, intelectual, austeridade, racional
aceitavel (acceptable): adequado, coerente, consistente, apropriado, relevante, interessante, eficaz
superavit (surplus): faturamento, financeiro, empreendimento, importador, contribuinte, mercado, comprador, produto, fornecedor, exportador
desenvolvimento (development): desenvolvimento, crescimento, progresso, fortalecimento, planejamento, enriquecimento, incremento, empreendedorismo

# 2014
pessimo (terrible): mau, precário, lamentável, equivocado, desconfortável, desastroso, desfavorável
imoral: imoral, inaceitável, preconceituoso, injusto, racista, abusivo, cruel, inadmissível, imprudente, incompetente, perverso, preconceituosa, ridículo, vergonhoso, falho
inaceitavel (unacceptable): inaceitável, inadmissível, imoral, injusto, lamentável, injusta, inconstitucional, racista, imprudente, inevitável, ilegal
deficit: déficit, endividamento, desemprego, débito, mal-estar, incremento, esvaziamento, desconforto, estresse, agravamento, excesso, prejuízo, congestionamento, esgotamento
estagnacao (stagnation): estagnação, recessão, instabilidade, retração, crise, decadência, hiperinflação, turbulência, desorganização, desaceleração, deterioração, paralisação

otimo (excelent): excelente, destacado, interessante, melhor, importantíssimo, excepcional, inovador
moral: racionalidade, honestidade, disciplina, dignidade, civilidade, humildade, discernimento, intelectual, austeridade, intolerância, consciência, obediência, moderação, doutrina, prudência
aceitavel (acceptable): compreensível, conveniente, viável, admissível, consensual, satisfatório, razoável, confiável, adequado, recomendável, satisfatória
superavit (surplus): superávit, faturamento, bancário, financeiro, adiantamento, embargo, empreendimento, bilhão, trilhão, dólar, salário, contribuinte, monetário, crédito
desenvolvimento (development): desenvolvimento, crescimento, aprimoramento, progresso, fortalecimento, planejamento, enriquecimento, aperfeiçoamento, avanço, fomento, incremento, empreendedorismo

# 2018
pessimo (terrible): mau, equivocado, deprimido, desastroso, isento, preconceituoso, infeliz, desorganizado
imoral: imoral, preconceituoso, injusto, indecente, racista, abusivo, ignorante, desonesto, subversivo
inaceitavel (unacceptable): imoral, injusto, inapropriado, ineficaz, inconstitucional, racista, imprudente, indecente, ilegal, indigno, falho, insulto, impotente, incompetente
deficit: endividamento, desemprego, esvaziamento, desconforto, estresse, agravamento, congestionamento, esgotamento
estagnacao (stagnation): instabilidade, crise, derrocada, debilidade, anarquia, estiagem, ruptura, desordem

otimo (excelent): excelente, destacado, interessante, melhor, unico, excepcional, inovador, bacana
moral: racionalidade, honestidade, equidade, disciplina, conduta, dignidade, civilidade, discernimento, intelectual
aceitavel (acceptable): conveniente, adequado, apropriada, sensato, coerente, consistente, apropriado, relevante, interessante, possivel, eficaz, imparcial, preciso
superavit (surplus): faturamento, financeiro, adiantamento, empreendimento, importador, contribuinte, mercado, comprador
desenvolvimento (development): desenvolvimento, crescimento, aprimoramento, progresso, fortalecimento, enriquecimento, fomento, incremento
