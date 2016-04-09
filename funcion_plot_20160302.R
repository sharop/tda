
###Se requiere igraph
library(igraph)


###Esta parte genera una matriz... no es necesaria utilizar una vez que se tenga la matriz verdadera
set.seed(981213)
n= 15
matriz <- matrix(sample(x=seq(0,9),size=n*n,replace=T,prob=c(.5,rep(.5*(1/9),9))),nrow=n)
matriz

###Este genera un código de colores y lo adecua a la matriz en segmentos iguales (función cut). NO es necesaria una vez que se tengan los colores
ncolores=10
colores <- merge(data.frame(cuts=cut(rowSums(matriz),ncolores)),data.frame(cuts=levels(cut(rowSums(matriz),ncolores)),colores=rainbow(ncolores)),by='cuts')$colores
tam <- log(rowSums(matriz))*5

###Esta es la función de gráfica. Recibe lo siguiente como parámetro:
#mat - La matriz de adyacencia
#colores - Vector de colores en formato RGB hexadecimal (ej: #AA00BB). Tiene que tener tantos elementos como nodos hay en el grafo
#tam - Vector de tamaños. Tiene que tener tantos elementos como nodos hay en el grafo
#zoom - Vector de 4 elementos que define un área para hacer Zoom en el grafo. Del tipo c(X1,Y1,X2,Y2)
#lay - layout: 'kamada' es el default y se obtiene un layout Kamada-Kawai. Con cualquier otro string se hace un layout Fruchterman-Reingold

grafica <- function(mat,colores=c(0),tam=c(1),zoom,lay='kamada') {
  if(colores==c(0)) {
    colores <- rep('#e2e0e0',dim(mat)[1])
  }
  if(tam==c(1)) {
    tam <- rep(1,dim(mat)[1])
  }
  g <- graph.adjacency(mat,mode='undirected',weighted=T)
  g <- simplify(g)
  if(lay=='kamada') {
    par(mfrow=c(1,2))
    plot(g,vertex.color=colores,vertex.size=tam,edge.arrow.size=.2,layout=layout.kamada.kawai)
    plot(g,vertex.color=colores,vertex.size=tam,edge.arrow.size=.2,xlim=zoom[1:2],ylim=zoom[3:4],layout=layout.kamada.kawai)
    par(mfrow=c(1,1))
  }
  else {
    par(mfrow=c(1,2))
    plot(g,vertex.color=colores,vertex.size=tam,edge.arrow.size=0,layout=layout.fruchterman.reingold)
    plot(g,vertex.color=colores,vertex.size=tam,edge.arrow.size=0,xlim=zoom[1:2],ylim=zoom[3:4],layout=layout.kamada.kawai)
    par(mfrow=c(1,1))
  }
  
}

###Llamada de ejemplo:
grafica(matriz,colores,tam,c(-.4,.4,-.2,.1),'kamada')


