IrishRulesModel <-
function(data, param = NULL){

  
  # Parameter list
  if (is.null(param)){
    rh_thresh <- 90
    temp_thres <- 10
    hours <- 12   #sum of hours before EBH accumulation
    wet_before <- 3
    wet_after <- 3
  }else{
    #pass a vector of parameters 
    rh_thresh <- as.numeric(param[2])
    temp_thres <- as.numeric(param[3])
    hours <- as.numeric(param[4])   
    wet_before <- as.numeric(param[5])
    wet_after <- as.numeric(param[6])
    lw_rhum <- param[7]           #if is NA then only rain data will be used
  }
  
  data  %>% collect  %>% .[["rain"]] -> rain
  data  %>% collect  %>% .[["rhum"]] -> rh
  data  %>% collect  %>% .[["temp"]] -> temp
  if(sum(is.na(with(data, rain, temp,rhum)))>5){
    stop(print("sum of NAs is more than 5"))
  }
  
  #"Out of boounds"
  rain <- c(rain, rep(0,20))
  temp <- c(temp, rep(0,20))
  rh <- c(rh, rep(0,20))
  
  rain <- na.approx(rain, maxgap = 5)
  temp <- na.approx(temp, maxgap = 5)
  rh <- na.approx(rh, maxgap = 5)
  # rain <- as.vector(data[,9])
  # temp <- data[,6]
  # rh <- data[,7]
  # class(temp)
  # check if there is 12 hours of conditions: rh >= 90 and t>= 10
  criteria<- as.numeric(temp>=temp_thres & rh>=rh_thresh) #Specify criteria> data$crit
  
  #cumulative sum with restart at zero
  #criteria_sum <-  ave(criteria, cumsum(criteria == 0), FUN = cumsum)
  #data$rs33 <- with(rle(data$rs1!=0), sequence(lengths)*rep(values, lengths))
  criteria_sum <- ave(coalesce(criteria, 0), data.table::rleid(zoo::na.locf(criteria != 0,maxgap = 3)), FUN = cumsum)
  
  
  #cumulative sum with restart at zero
  # criteria_sum <-  ave(criteria, cumsum(criteria == 0), FUN = cumsum)
  #data$rs33 <- with(rle(data$rs1!=0), sequence(lengths)*rep(values, lengths))
  risk <- rep(0, length(temp))
  
  criteria_met12  <-as.numeric( criteria_sum >= hours )
  idx             <-which(criteria_sum == hours)
  
  
  #If there are no accumulations return vector with zeros
  if (sum(criteria_sum == hours)==0){                #breaks the loop if there is no initial accumulation of 12 hours
    head(risk,-20)
    } else{
        for (j in 1 : length(idx)){   
       
          #switch that looks if there was wetness: first rain, then both rain and rh, if rh exists
          if(if (is.na(lw_rhum)){                                            #if thee is no input for rhum threshold
            (sum(rain[(idx[j]-wet_before):(idx[j]+wet_after)])>= 0.1)           #just see rain sum
          }else{
            any((any(rh[(idx[j]-wet_before):(idx[j]+wet_after)]>= lw_rhum)) |   #take both as possible switches
                (sum(rain[(idx[j]-wet_before):(idx[j]+wet_after)])>= 0.1))   
          }) # outputs true or false
          {         
            n <- idx[j]        #start accumulation from `hours` hour
          } else {         
            n <- idx[j]+4      #start accumulation from `hours` hour
          }    
          s <- criteria_met12[n]
          # if a break of less than or equal to 5 hours  
          m <- n-1;
          while (s==1)
          { 
            risk[n] <- risk[m]+1  
            n <- n+1;
            m <- n-1;
            s <- criteria[n] 
            if ( s==0 && (criteria[n+2]==1)) {
              n = n+2;
              s=1;
            } else if ( s==0 && (criteria[n+3]==1)) {
              n = n+3;
              s=1;
            } else if ( s==0 && (criteria[n+4]==1)) {
              n = n+4;
              s=1;
            } else if( s==0 && (criteria[n+5]==1)) {
              n = n+5;
              s=1;
            }      
          }  
          
      }   
      head(risk,-20) #remove last 20 values that were added to vectors to prevent "Out of bounds" issue
    
    }
  
}
