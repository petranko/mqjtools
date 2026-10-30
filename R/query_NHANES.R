#' 查询和下载NHANES单字段全年份信息
#'
#' 基于nhanesA和nhanesdata一键整理单字段全年份信息
#'
#' @param variable_ids 字段id，可以为c()列表，务必对应单个字段，否则将出现数据错乱
#' @param variable_rename 重命名的处理后字段名
#' @param variable_label 字段中赋予的label信息
#'
#' @return list(), 包含labeled data.frame、处理详情信息list.
#'
#' @family formatting helpers
#' @seealso [fmt_num()]
#'
#' @export
#' @examples
#' 
# query_NHANES(variable_ids = c("DIQ080"), variable_rename = "diabetes_retinopathy", variable_label = "Diabetes affected eyes/had retinopathy")
query_NHANES = function(variable_ids = NULL, variable_rename = NULL, variable_label = NULL){
  library(data.table)
  library(tidyverse)
  library(nhanesA)
  library(nhanesdata)
  
  manifest <- nhanesManifest()
  if(is.null(variable_ids) | is.na(variable_ids) | length(variable_ids) < 1){
    stop("variable_ids有误！")
  }
  if(is.null(variable_rename) | is.na(variable_rename) | length(variable_rename) != 1){
    stop("variable_rename有误！")
  }
  if(is.null(variable_label) | is.na(variable_label) | length(variable_label) != 1){
    stop("variable_label有误！")
  }
  
  
  for(i in 1:length(variable_ids)){
    # i = 1
    table.list = nhanesA::nhanesSearchVarName(variable_ids[i])
    table.main = data.frame()
    check.list = list()
    for(c in 1:length(table.list)){
      # c = 1
      table.this = nhanes(nh_table = table.list[c], 
                          translated = TRUE, # 变量是否被翻译。
                          cleanse_numeric = T, # 如果为真，数值变量中的某些特殊代码（如“拒绝”和“不知道”）将被转换为 NA
                          adjust_timeout = T # 一般默认即可
      )
      table.this = table.this[c("SEQN", variable_ids[i])]
      table.this$YEARs = manifest$Years[manifest$Table == table.list[c]]
      
      colnames(table.this) = c("SEQN", variable_rename, "YEARs")
      for(h in 1:ncol(table.this)){
        attr(table.this[,h], "label") = c("Sample id", variable_label, "Years")[h]
      }
      table.main = bind_rows(table.main, table.this)
      check = paste0("Years[", manifest$Years[manifest$Table == table.list[c]], "]:",
                     paste(names(table(table.this[,2])), table(table.this[,2]), collapse = ","), "; NA_count ", sum(is.na(table.this[,2])), ", NA_percent ", as.character(round(sum(is.na(table.this[,2])) / nrow(table.this), digits = 4) * 100), "%")
      check = list(check)       
      names(check) = manifest$Years[manifest$Table == table.list[c]]
      check.list = append(check.list, check)
    }
    info = ""
    for(x in check.list){
      info = paste(info, x, sep = "\n")
    }
    
    cat("=======================================\n")
    cat(paste0("variable_ids:", paste(variable_ids)))
    cat(paste0("variable_rename:", variable_rename))
    cat(paste0("variable_label:", variable_label))
    cat(info)
    cat("=======================================\n")
  }
  return(list("table" = table.main, "info" = check.list))
}