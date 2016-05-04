#!/usr/bin/env python
# -*- coding: utf-8 -*-


import sys
import pandas as pd
from sklearn import decomposition
import numpy as np
import copy
import json
from sklearn import preprocessing

archivo_csv = sys.argv[1]

####Leemos el archivo csv que se pasa la ubicacion desde linea de comandos
print "USER INFO Leyendo archivo"
datos_crudos = pd.read_csv(archivo_csv)
datos = preprocessing.normalize(datos_crudos)
datos = pd.DataFrame(datos, columns = datos_crudos.columns)

####Obtenemos la primera componente principal
print "USER INFO Sacando PCA"
pca = decomposition.PCA()
X_pca = pca.fit_transform(datos)
primer_componente = [X_pca[i][0] for i in range(len(X_pca))]


####Obtenemos los filtros con PCA, desde linea de comandos se define el numero 
####de intervalos y el porcentaje de overlaping
print "USER INFO Obteniendo filtros"
num_intervalos = int(sys.argv[2])
porcentaje_overlap = float(sys.argv[3])
centros = np.linspace(min(primer_componente), max(primer_componente), num_intervalos)
longitud_intervalo = centros[1] - centros[0]

intervalos = []
for centro in centros:
	intervalos.append([centro-(.5+porcentaje_overlap)*longitud_intervalo,
		centro+(.5+porcentaje_overlap)*longitud_intervalo])

####Para cada intervalo definimos que observaciones estan dentro del filtro por los indices
print "USER INFO Sacando observaciones por filtro"
intervalo_indices = {}
conteo_indices = 1
for intervalo in intervalos:
    lista_indices = []
    for indice in range(len(primer_componente)):
        if primer_componente[indice] > intervalo[0] and primer_componente[indice]< intervalo[1]:
            lista_indices.append(indice)
    intervalo_indices[conteo_indices] = lista_indices
    conteo_indices += 1

####Estas son las funciones para hacer el clustering de knn-bfs
def conecta_vecinos_graph(vecinos,observaciones):
    from sklearn.neighbors import NearestNeighbors
    import numpy as np

    X = copy.copy(np.array(observaciones))
    nbrs = NearestNeighbors(n_neighbors=vecinos+1, algorithm='ball_tree').fit(X)
    distances, indices = nbrs.kneighbors(X)

    vecinos_cercanos_graph = {}
    for index in indices:
        vecinos_cercanos_graph[index[0]] = set(index[1:])
        
    return vecinos_cercanos_graph

def bfs(graph, start):
    visited, queue = set(), [start]
    while queue:
        vertex = queue.pop(0)
        if vertex not in visited:
            visited.add(vertex)
            queue.extend(graph[vertex] - visited)
    return visited

####Comenzamos el clustering, el numero de vecinos debes ser decidido desde linea de comandos
print "USER INFO Construyendo clusters por filtro"

vecinos = int(sys.argv[4])
intervalos_clusters = {}

for key in intervalo_indices.keys():
    print "USER INFO Construyendo clusters por filtro numero: " + str(key)

    indices_clusters = {} ###Aqui voy a guardar los indices para cada cluster

    ##En intervalo_indices esta para cada intervalo, los indices de las observaciones que entran
    ##dentro del intervalo, entonces filtramos para cada intervalo

    #Aqui vamos a ir metiendo los indices de las observaciones que se van clusterizando
    indices = range(len(datos.ix[intervalo_indices[key]]))

    #Aqui vamos a ir metiendo los indices de las observaciones que faltan por clusterizar
    indices_restantes = copy.copy(indices)

    #Hacemos una copia de los datos para no modificarlos en las iteraciones
    nuevas_observaciones = copy.copy(datos.ix[intervalo_indices[key]].values)
    
    ##Es para numerar los numeros de clusters que salgan
    cluster = 1

    while len(nuevas_observaciones)>0:

        if len(nuevas_observaciones)>vecinos:
        ##Creamos el grafo de vecinos mas cercanos
            graph_vecinos = conecta_vecinos_graph(vecinos,nuevas_observaciones)
            
            ##Vemos las grafo completo que va a ser un cluster
            grupo = list(bfs(graph_vecinos,0))

            ##Estos son los indices del primer cluster
            indices_grupo = [indices_restantes[idx] for idx in grupo]

            ##Del total de indices les quitamos los que ya se clusterizaron
            indices_restantes = [indices_restantes[idx] for idx in range(len(indices_restantes)) if idx not in grupo]
            
            ##Asignamos al primer cluster sus indices
            indices_clusters[cluster] = indices_grupo

            ##Filtramos los datos para solo quedarnos con los que aun no estan clusterizados
            nuevas_observaciones = [nuevas_observaciones[idx] for idx in range(len(nuevas_observaciones)) if idx not in grupo]
            
            ##vamos por el siguiente cluster
            cluster += 1
        else:
        ##Cuando a veces quedan muy pocas observaciones, menos de las necesarias para hacer k-vecinos, asignamos
        ##esas restantes a otro cluster
            indices_clusters[cluster]=indices_restantes
            break
    
    ####Sabemos para cada cacho del intervalos sus clusters, tenemos para cada cluster los indices, ahora es necesario
    ####traducir esos indices locales a los indices de los datos originales, hacemos la conexion con los datos que teniamos
    ####de indices por intervalo
    for cluster_local in indices_clusters.keys():
        nom_cluster = "inter_" + str(key) + "_clust_" + str(cluster_local)
        intervalos_clusters[nom_cluster] = [intervalo_indices[key][idx] for idx in indices_clusters[cluster_local]]

####Creamos el json para guardar los datos de los nodos
print "USER INFO Creando JSONS"
primer_componente = pd.DataFrame(primer_componente, columns = ["PC1"]) #Solo para poder acceder a los datos por indice
nodos = []
for nodo in range(len(intervalos_clusters.keys())):
    nombre = intervalos_clusters.keys()[nodo]
    datos_nodo = {'group': nodo,
                  'name' : nombre,
                  'size':len(intervalos_clusters[nombre]),
                  'PC1': round(float(primer_componente.ix[intervalos_clusters[nombre]].mean()),2)
                  }
    for var in datos.columns:
        promedio_var = datos_crudos[var].ix[intervalos_clusters[nombre]].mean()
        datos_nodo["mean_"+var] = round(float(promedio_var),2)
        
    nodos.append(datos_nodo)

####El json para los datos de las conexiones y distancias
links = []
for idx_1 in intervalos_clusters.keys():
    for idx_2 in intervalos_clusters.keys():
        if idx_1 != idx_2:
            #Elementos en cada cluster
            elementos_uno = float(len(intervalos_clusters[idx_1]))
            elementos_dos = float(len(intervalos_clusters[idx_2]))
            
            #El cluster con el menor numero de elementos
            minimo_elementos = min(elementos_uno, elementos_dos)
            
            #cuantos elementos comparten cada cluster
            elementos_compartidos = len(list(set(intervalos_clusters[idx_1]).intersection(intervalos_clusters[idx_2])))
            
            #Asignamos a la matriz la distancia como 1 - num_elemntos_comp / minim_elementos
            distancia_intercluster = 1- (elementos_compartidos/minimo_elementos)
            if distancia_intercluster !=1:
                links.append({
                        'source':intervalos_clusters.keys().index(idx_1),
                        'target':intervalos_clusters.keys().index(idx_2),
                        'value':distancia_intercluster
                    })

####Finalmente guardamos estos jsons para leerlos despues en R
print "USER INFO Guardando JSONS"
with open('datos_nodos.json', 'w') as outfile:
    json.dump(nodos, outfile)
    
with open('datos_links.json', 'w') as outfile:
    json.dump(links, outfile)                
