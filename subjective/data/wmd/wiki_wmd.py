# -*- coding: utf-8 -*-
from __future__ import print_function
import os

import nltk
import numpy as np
from sklearn.feature_extraction.text import CountVectorizer
from gensim.models import KeyedVectors
from scipy.spatial.distance import cosine
from sklearn.metrics import euclidean_distances
from pyemd import emd

import sys
import pandas as pd

path_processed_text = sys.argv[1]
path_output = sys.argv[2]

def clean_stopwords(text, stop_words_list):
    list_words = text.split()
    list_clean_text = []
    for word in list_words:
        if word not in stop_words_list:
            list_clean_text.append(word)
    return " ".join(list_clean_text)

def loadStopWordsPT(filename):
    lines = [line.rstrip('\n').strip() for line in open(filename)]
    return lines

argumentacao = "a_ponto ao_menos apenas ate ate_mesmo incluindo inclusive mesmo nao_mais_que nem_mesmo no_minimo o_unico a_unica pelo_menos quando_menos quando_muito sequer so somente a_par_disso ademais afinal ainda alem alias como e e_nao em_suma enfim mas_tambem muito_menos nao_so nem ou_mesmo por_sinal tambem tampouco assim com_isso como_consequencia consequentemente de_modo_que deste_modo em_decorrencia entao logicamente logo nesse_sentido pois por_causa por_conseguinte por_essa_razao por_isso portanto sendo_assim ou ou_entao ou_mesmo nem como_se de_um_lado por_outro_lado mais_que menos_que nao_so tanto quanto tao como desde_que do_contrario em_lugar em_vez enquanto no_caso quando se se_acaso senao de_certa_forma desse_modo em_funcao enquanto isso_e ja_que na_medida_que nessa_direcao no_intuito no_mesmo_sentido ou_seja pois porque que uma_vez_que tanto_que visto_que ainda_que ao_contrario apesar_de contrariamente contudo embora entretanto fora_isso mas mesmo_que nao_obstante nao_fosse_isso no_entanto para_tanto pelo_contrario por_sua_vez porem posto_que todavia"
modalizacao = "achar aconselhar acreditar aparente basico bastar certo claro conveniente crer dever dificil duvida efetivo esperar evidente exato facultativo falar fato fundamental imaginar importante indubitavel inegavel justo limitar logico natural necessario negar obrigatorio obvio parecer pensar poder possivel precisar predominar presumir procurar provavel puder real recomendar seguro supor talvez tem tendo ter tinha tive verdade decidir"
valoracao = "absoluto algum alto amplo aproximado bastante bem bom categorico cerca completo comum consideravel constante definitivo demais elevado enorme escasso especial estrito eventual exagero excelente excessivo exclusivo expresso extremo feliz franco franqueza frequente generalizado geral grande imenso incrivel lamentavel leve maioria mais mal melhor menos mero minimo minoria muito normal ocasional otimo particular pena pequeno pesar pior pleno pobre pouco pouquissimo praticamente prazer preciso preferir principal quase raro razoavel relativo rico rigor sempre significativo simples tanto tao tipico total tremenda usual valer"
sentimento = "abalar abater abominar aborrecer acalmar acovardar admirar adorar afligir agitar alarmar alegrar alucinar amar ambicionar amedrontar amolar animar apavorar apaziguar apoquentar aporrinhar apreciar aquietar arrepender assombrar assustar atazanar atemorizar aterrorizar aticar atordoar atormentar aturdir azucrinar chatear chocar cobicar comover confortar confundir consolar constranger contemplar contentar contrariar conturbar curtir debilitar decepcionar depreciar deprimir desapontar descontentar descontrolar desejar desencantar desencorajar desesperar desestimular desfrutar desgostar desiludir desinteressar deslumbrar desorientar desprezar detestar distrair emocionar empolgar enamorar encantar encorajar endividar enervar enfeiticar enfurecer enganar enraivecer entediar entreter entristecer entusiasmar envergonhar escandalizar espantar estimar estimular estranhar exaltar exasperar excitar execrar fascinar frustar gostar gozar grilar hostilizar idolatrar iludir importunar impressionar incomodar indignar inibir inquietar intimidar intrigar irar irritar lamentar lastimar louvar magoar maravilhar melindrar menosprezar odiar ofender pasmar perdoar preocupar prezar querer recalcar recear reconfortar rejeitar repelir reprimir repudiar respeitar reverenciar revoltar seduzir sensibilizar serenar simpatizar sossegar subestimar sublimar superestimar surpreender temer tolerar tranquilizar transtornar traumatizar venerar" #malquerer obcecar
pressuposicao = "adivinhar admitir agora aguentar ainda antes atentar atual aturar comecar compreender conseguir constatar continuar corrigir deixar demonstrar descobrir desculpar desde desvendar detectar entender enxergar esclarecer escutar esquecer gabar ignorar iniciar interromper ja lembrar momento notar observar olhar ouvir parar perceber perder pressentir prever reconhecer recordar reparar retirar revelar saber sentir tolerar tratar ver verificar"

raw_stop_words = loadStopWordsPT('stopwords.txt')

argumentacao = clean_stopwords(argumentacao, raw_stop_words)
modalizacao = clean_stopwords(modalizacao, raw_stop_words)
valoracao = clean_stopwords(valoracao, raw_stop_words)
sentimento = clean_stopwords(sentimento, raw_stop_words)
pressuposicao = clean_stopwords(pressuposicao, raw_stop_words)

SENTENCE_SIZE_THRESHOLD = 2

def remove_dots(sentence):
    sentence = re.sub('\.*', '', sentence)
    return sentence    

def valid_sentence_size(sentence):
    size = len(sentence.split())
    if size >= SENTENCE_SIZE_THRESHOLD:
        return True
    return False

def is_valid_sentence(sentence):
    sentence = remove_dots(sentence)
    sentence = ' '.join(sentence.split())
    return valid_sentence_size(sentence), sentence

def text_rate(list_lex_rate):
    if len(list_lex_rate) > 0:
        return np.mean(list_lex_rate)
    return -1

def check_value(w):
    if(w in vocab_dict):
        return(vocab_dict[w])
    return 0

def lexicon_rate(lexicon, comment):
    vect = CountVectorizer(token_pattern=pattern, strip_accents=None).fit([lexicon, comment])
    v_1, v_2 = vect.transform([lexicon, comment])
    v_1 = v_1.toarray().ravel()
    v_2 = v_2.toarray().ravel()
    W_ = W[[check_value(w) for w in vect.get_feature_names()]]
    D_ = euclidean_distances(W_)
    v_1 = v_1.astype(np.double)
    v_2 = v_2.astype(np.double)
    v_1 /= v_1.sum()
    v_2 /= v_2.sum()
    D_ = D_.astype(np.double)
    D_ /= D_.max()
    lex=emd(v_1, v_2, D_)
    return(lex)

def split_text_into_sentences(lexicon, text):
    sent_text = nltk.sent_tokenize(text)
    lex_rate = list()
    for sentence in sent_text:
        valid, sentence = is_valid_sentence(sentence)
        if(valid):
            lex_rate.append(lexicon_rate(lexicon, sentence))
    return(text_rate(lex_rate))

def wmd_ratings(text):
    arg = split_text_into_sentences(argumentacao, text)
    mod = split_text_into_sentences(modalizacao, text)
    val = split_text_into_sentences(valoracao, text)
    sen = split_text_into_sentences(sentimento, text)
    pre = split_text_into_sentences(pressuposicao, text)
    rates = list([text, arg, sen, val, mod, pre])
    return(rates)

wv = KeyedVectors.load_word2vec_format('wiki_vectors_format_with_comments_without_stopwords.bin', binary=False, unicode_errors="ignore")
wv.init_sims()

pattern = "(?u)\\b[\\w-]+\\b"

fp = np.memmap("embed.dat", dtype=np.double, mode='w+', shape=wv.syn0norm.shape)
fp[:] = wv.syn0norm[:]
with open("embed.vocab", "w") as f:
    for _, w in sorted((voc.index, word) for word, voc in wv.vocab.items()):
        print(w.encode('utf-8'), file=f)

vocab_len = len(wv.vocab)
del fp, wv

W = np.memmap("embed.dat", dtype=np.double, mode="r", shape=(vocab_len, 300))

with open("embed.vocab") as f:
    vocab_list = map(str.strip, f.readlines())
vocab_dict={w:k for k, w in enumerate(vocab_list)}

with open(path_processed_text) as f:
    texts=f.readlines()
texts = [x.strip() for x in texts]

lexicons_rates = list()
iter_count = 0
for text in texts:
    iter_count += 1.
    if(iter_count%10000==0):
        print(float(iter_count/len(texts)))
    rates = wmd_ratings(text)
    lexicons_rates.append(rates)

ratings_df = pd.DataFrame(lexicons_rates, columns=['text','arg','sen','val','mod','pre'])

ratings_df.to_csv(path_output, index=False)
