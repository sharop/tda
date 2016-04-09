#CREATING A TOY DATASET TWO LEVELS
minimo <- runif(1)*1
maximo <- 1+runif(1)*9
df1 <- data.frame(x1=seq(minimo,maximo,by=0.001))
df1$x2 <- c(rnorm(n=floor(dim(df1)[1]/2),mean=10,sd=2),  #let's make this variable induce some clusters
            rnorm(n=ceiling(dim(df1)[1]/2),mean=0,sd=1))


df <- df1       #choose a dataset
plot(df)

#----------------------------- PACKAGES -----------------------------

#install.packages("fpc")
#install.packages("kernlab")
#install.packages("igraph")
#install.packages("dbscan")
library(fpc)
library(dbscan)
library(igraph)
library(kernlab)

###-------------------------FUNCTIONS------------------------------------------------
## We obtain a clustering that attemps to not depend on the eps parameter
## we give a maximum eps for attempting clustering and evaluate on the percentage of 
## noise obtained
noClust<-function(data, eps=0.7, eps_cl=6.5, np=.1){
  #Default parameters for dbscan
  p_noise <- 0.05       # we use this as a rule of thumb
  ##Number of clusters detected
  numClust<-0
  ##Noise percentage
  noise_perc<-1
  MinPts <- p_noise*dim(data)[1]
  # We iterate eps through an geometric function starting on the given value
  for(j in 0:10){
    eps<-eps+j*eps
    ## We iterate also on the eps_cl parameter with an exponential function
    for(i in 0:3 ){
      result<-optics(data,eps=eps,minPts=MinPts,eps_cl = eps_cl*10**-i)
      noise_perc=length(result$cluster[result$cluster==0])/length(result$cluster[result$cluster!=0])
      if (noise_perc < np) {
        numClust<-max(result$cluster)
        return(list(cluster=result$cluster, noise_perc=noise_perc, num_clust=numClust))
      }
    }
  }
  list(cluster=result$cluster, noise_perc=noise_perc)
}
#----------------------------- NECESSARY PARAMETERS -----------------------------
var_o <- df$x1    #variable we will use to make the overlapping subsets
#var_o <- df4$V1   #if we want to use kernel pca variable to cut
n_int <- 6       #number of intervals we want
p <- 0.2          #proportion of each interval that should overlap with the next
#parameters for dbscan
eps <- 0.7            #epsilon makes the number of clusters VERY unstable  !!!!!
p_noise <- 0.05       #

#----------------------------- CREATING THE INTERVALS -----------------------------

#this section will create a data frame in which we will construct overlapping intervals
intervals_centers <- seq(min(var_o),max(var_o),length=n_int)  #basic partition = centers
interval_length <- intervals_centers[2]-intervals_centers[1]  #to create the overlaps of p% of this length
intervals <- data.frame(centers=intervals_centers)            #create a data frame
#create the overlapping intervals  
intervals$min <- intervals_centers - (0.5+p)*interval_length                     
intervals$max <- intervals_centers + (0.5+p)*interval_length
#decent name for the intervals e.g    [5.34;6.53)     [6.19;7.39)
intervals$interval <- seq(1,n_int)
intervals$name <- with(intervals, sprintf("[%.2f;%.2f)",min,max))

#function that will split the variable according to the invervals
res <- lapply(split(intervals,intervals$interval), function(x){   
  return(df[var_o> x$min & var_o <= x$max,])     #res will be a list with each element res[i]
})                                                #being the points on the i'th subset

#res


#ITERATE EVERY ELEMENT OF THE LIST (res[i]) AND CLUSTERIZE INSIDE
ints<-list()
counter1<-1;counter2<-1

for(i in 1:(n_int-1)){
  df1<-as.data.frame(res[[i]])
  df2<-as.data.frame(res[[i+1]])
  
  if(i==1){
    MinPts <- p_noise*dim(df1)[1]
    result1<-(noClust(df1))
    df1$cluster1 <- result1$cluster
    
    #create columns in the original matrix to show which cluster they belong to
    df[dim(df)[2]+i]<-rep(0,dim(df)[1])
    df[row.names(df1),dim(df)[2]]<-result1$cluster
    
  }else{result1 <- result2              #use the results for the last iteration
  df1$cluster1 <- result1$cluster #this ensures that the cluster labels will be correct for the adj. matrix
  }
  
  MinPts <- p_noise*dim(df2)[1]
  result2<-(noClust(df2))
  df2$cluster2 <- result2$cluster
  
  #create columns in the original matrix to show which cluster they belong to
  df[dim(df)[2]+1]<-rep(0,dim(df)[1])
  df[row.names(df2),dim(df)[2]]<-result2$cluster
  
  intersection <- merge(df1,df2,all=TRUE)            #points in the intersection
  intersection[is.na(intersection)] <- 0
  ints[[i]]<-as.data.frame(unique(intersection[3:4]))               #list of all the clusters that intersect
  
}





#####CODIGO PARA CALCULAR LA CERCANIA ENTRE CLUSTERS######
#Bajo el supuesto que leemos una base que tiene columnas para cada intervalo

#Leemos la base de datos con los intervalos
base <- df
#Creamos una columna para los clusters
base$clusters<-0

#Columna en donde empieza el intervalo 1:
int_ini <- 3
#Columna en donde se ubica el ultimo intervalo:
int_fin <- 8
#Columna donde se creo la columna de "clusters":
col_cluster <- 9


for(i in seq(nrow(base[,int_ini:int_fin]))){
  temp<-c()
  for(m in seq(int_ini,int_fin)){
    if (base[i,m] > 0){
      
      temp<-c(paste0(temp,base[i,m],sep = ","))
    }
  }
  if(length((temp))>0){
    aux<-unlist(strsplit(temp,","))
    aux2<-unique(aux)
    aux3<-paste(aux2,collapse=",")
    base[i,col_cluster]<-aux3
  }
}

base <- data.frame(base$clusters)
names(base) <- c("clusters")

#Creamos una variable para enumerar la observacion
base$obs <- paste("obs",seq(1,length(base$clusters)))

#Detectamos los clusters
num_clusters <- sort(unique(strsplit(paste0(base$clusters, collapse=","),",")[[1]]))
clusters <- length((num_clusters))

#Creamos una columna con ceros para cada cluster
for(x in num_clusters){
  base[[paste("c",x,sep="_")]] <- rep(0,nrow(base))
}

#Para cada columna que creamos agregamos un 1 según el cluster al que pertenece la obs
base$clusters<- as.character(base$clusters)


#Ojo es x+3, porque en la columna 3 en adelante es donde va vaciar los "1" de cada cluster
for(i in seq(nrow(base))){
  vector <- strsplit(base$clusters[i], ",")[[1]]
  vector <- sort(as.numeric(vector))
  for(x in vector){
    base[i,(x+3)] <- 1
  }
}

#install.packages('dplyr')
library(dplyr)

#En este paso nombras las columnas de los clusters, se tiene que ajustar segun el numero de clusters
grp_cols <-c("c_0","c_1","c_2")

#Nos va servir para dplyr
dots <- lapply(grp_cols,as.symbol)

#Numero de observaciones en cada cluster
sumas_columnas <- apply(base[grp_cols], 2,sum)

#Resumiendo por cluster
resumen_clusters <- base %>%
  group_by_(.dots=dots) %>%
  summarise(conteo = n()) %>%
  ungroup()

#Identificamos la cercania entre clusters, contando cuantos elementos comparten
resumen_clusters$cercania <- rep(0,nrow(resumen_clusters))

#Matriz de adyacencia ponderada por sus pesos
m_adj <- matrix(0L, nrow=length(num_clusters),ncol=length(num_clusters),dimname=list(c(grp_cols),c(grp_cols)))

for(i in seq(nrow(resumen_clusters))){
  man <- sum(resumen_clusters[i,paste("c",num_clusters, sep ="_")])
  if(man > 1 & man < clusters){
    logico <- resumen_clusters[i,paste("c",num_clusters, sep ="_")] > 0
    columnas <- grp_cols[logico]
    empalme <- resumen_clusters$conteo[i]
    porcentaje <- as.numeric(empalme/(sum(sumas_columnas[columnas])-empalme))
    resumen_clusters$cercania[i] <- 1-porcentaje
    m_adj[columnas[1],columnas[2]] <- resumen_clusters$cercania[i]
    m_adj[columnas[2],columnas[1]] <- resumen_clusters$cercania[i]
  }
}


#Resumen de la cercania entre clusters
resumen_clusters %>%
  filter(cercania > 0)

m_adj


#Vector de observaciones de cada cluster
obs_cluster <- apply(base[grp_cols], 2,sum)
obs_cluster
