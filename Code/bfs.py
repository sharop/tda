import random


parametros = {"perfil_1":{"media_1":5000,"desviacion_1":3000,
                         "media_2":5000,"desviacion_2":3000,
                         "media_3":5000,"desviacion_3":3000},
             "perfil_2":{"media_1":1000,"desviacion_1":3000,
                         "media_2":1000,"desviacion_2":3000,
                         "media_3":1000,"desviacion_3":3000},
              "perfil_3":{"media_1":9000,"desviacion_1":3000,
                         "media_2":9000,"desviacion_2":3000,
                         "media_3":9000,"desviacion_3":3000}
             }
perfiles = ["perfil_1","perfil_2","perfil_3"]
observaciones = []
perfil_obs = []
for idx in range(1000):
    perfil = random.sample(perfiles,1)
    perfil = perfil[0]
    perfil_obs.append(perfil)
    obs_1 = random.normalvariate(parametros[perfil]["media_1"], parametros[perfil]["desviacion_1"])
    obs_2 = random.normalvariate(parametros[perfil]["media_2"], parametros[perfil]["desviacion_2"])
    obs_3 = random.normalvariate(parametros[perfil]["media_3"], parametros[perfil]["desviacion_3"])

    observaciones.append([obs_1, obs_2, obs_3])

def conecta_vecinos_graph(vecinos,observaciones):
    from sklearn.neighbors import NearestNeighbors
    import numpy as np

    X = np.array(observaciones)
    nbrs = NearestNeighbors(n_neighbors=vecinos, algorithm='ball_tree').fit(X)
    distances, indices = nbrs.kneighbors(X)

    vecinos_cercanos_graph = {}
    for index in indices:
        vecinos_cercanos_graph[index[0]] = set(index[1:])

    return vecinos_cercanos_graph

graph_vecinos = conecta_vecinos_graph(5,observaciones)

def bfs(grafo, nodo0):
    visitado, cola = set(), [nodo0]
    while cola:
        vertex = cola.pop(0)
        if vertex not in visitado:
            visitado.add(vertex)
            if vertex not in grafo:
                grafo[vertex] = set()
                #print 'Tupla:', vertex, ',', len(grafo[vertex]), ',', len(visitado)
            cola.extend(grafo[vertex] - visitado)

    return visitado

def searchKNN(grafo, nodo0):
    klts = []
    faltantes = grafo
    visitados = bfs(grafo, nodo0)
    c=0
    while len(faltantes)>0:
        kls = {}

        for visitado in list(visitados):
            if grafo.has_key(visitado):
                kls[visitado]= grafo[visitado] #guardamos en el cluster
                del faltantes[visitado]
                visitados.remove(visitado)


        klts.append(kls)


        if len(faltantes) >0:
            print faltantes.keys()[0]
            print faltantes
            visitados = bfs(faltantes, faltantes.keys()[0])
    return klts

if __name__ =='__main__':
    #graph_vecinos = conecta_vecinos_graph(5, observaciones)
    grafo = {'A': set(['B', 'H', 'D']),
             'B': set(['A', 'D', 'C']),
             'C': set(['B', 'D']),
             'D': set(['C', 'B', 'H']),
             'E': set(['G', 'F']),
             'F': set(['E']),
             'G': set(['E']),
             'H': set(['A', 'D']),
             'I': set(['J'])}
    #searchKNN(graph_vecinos, 0)
    print searchKNN(grafo, 'A')
