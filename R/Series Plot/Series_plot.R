library(dplyr) # for data manipulation
library(tidyr) # to use pivot_wider() function
library(ggplot2) # to create plots
library(gridExtra) # to graphically display the tables
library(patchwork) # to combine the graph and the table
library(clinicalfd) # to use open source clinical data sets



# getting raw data
data("adlbc")

# filter raw data by population flags
filtredData <- adlbc %>% 
  dplyr::filter(paramcd %in% c("ALT", "AST"), saffl == "Y", avisitn >= 0)

# creating structured data by USUBJID variable for plots
plotData <- filtredData %>% group_by(usubjid, trta)  %>% slice(1) %>% 
  select(usubjid, trta)

# creating vectorized vector that contains USUBJID and TRTA variables for plots
subjects_trts <- lapply(1:nrow(plotData), function (i) {
  c(as.character(plotData$usubjid[i]), as.character(plotData$trta[i]))
})

# creating structured data by subject variable for filtering data
subjects_multi <- filtredData %>% group_by(usubjid) %>% 
  summarise(n=n()) %>% dplyr::filter(n>2)


# creating  variables which contain the values of upper (lower) limits of 
# parameter's normal range. If more than one upper (lower) limit exists the 
# minimum (maximum) limit has been taken
ulnValues <- filtredData %>% group_by(paramcd) %>%
  summarise(minUALN = min(a1hi), maxUALN = max(a1hi))

altMin = ulnValues$minUALN[ulnValues$paramcd == "ALT"]
astMin = ulnValues$minUALN[ulnValues$paramcd == "AST"]


# creating data for table located under the plot
tableData <- filtredData %>% group_by(usubjid) %>% 
  select(usubjid, chg, paramcd, ady)


invisible(lapply(subjects_trts, function(subject) {
  
  # creating a layout of a plot for each subjects
  plot <- ggplot(data = filtredData[filtredData[, "usubjid"] == subject[1],],
                 mapping = aes(x = as.factor(ady), y = aval, group = paramcd,
                               color = paramcd, linetype = paramcd, shape = paramcd))
  
  # selecting the type of plot based on the number of subject`s records
  if(subject[1] %in% subjects_multi$usubjid)
  {
    # if a subject has several records in data set, then create a series plot
    plot <- plot + geom_line() +
      # manually changing line types
      scale_linetype_manual(values = c("longdash", "dashed"))
  }
  
  # changing plot styles and adding additional information,
  # such as plot legend
  plot <- plot + geom_point() +
    # manually changing line/marker colors, and marker shapes
    scale_color_manual(values = c('purple','darkgreen')) +
    scale_shape_manual(values = c(1,8)) +
    # putting plot title, subtitle, and axes labels
    labs(
      title = "ALT and AST Results Over Time. (Safety Analysis Set)",
      subtitle = paste("Usubjid: ", subject[1], 
                       ", Treatment: ", subject[2], sep = ""), 
      y = "Analysis value", 
      x = "Study day relative to treatment start day"
    ) +
    # additional styling
    theme(
      # changing border style
      panel.border = element_rect(color = "black",
                                  linewidth = 0.3, fill = FALSE),
      # changing the graph grid style
      panel.grid.major = element_line(colour = "grey", linewidth = 0.3),
      # removing plot background
      panel.background = element_blank(),
      # position title and subtitle in center, changing size, family, face, and color
      plot.title = element_text(size = 12, family = "plain", face = "bold",
                                colour = "black", hjust = 0.5),
      plot.subtitle = element_text(size = 10, family = "plain", face = "plain",
                                   colour = "black", hjust = 0.5),
      # axes' labels size, family, and color
      axis.title = element_text(size = 10, family = "plain", colour = "black"),
      # axes' tick labels size, family, and color
      axis.text = element_text(size = 10, family = "plain", colour = "black"),
      # legend position
      legend.position = "bottom",
      # removing the title of the legend
      legend.title = element_blank(),
      # giving rectangle border to the legends
      legend.background = element_rect(colour = "black", linewidth = 0.2),
      # removing legend elements' background
      legend.key = element_blank()
    )
  
  # adding lines for "ALT ULN" and "AST ULN" values and labels for them
  plot <- plot +
    geom_hline(yintercept = astMin, color = "black", linewidth = 0.3) +
    geom_hline(yintercept = altMin, color = "black", linewidth = 0.3) +
    annotate("text", x = Inf, y = altMin, label = "ALT ULN",
             fontface = "plain", family = "plain", color = "black",
             size = 2.2, hjust = 1.2, vjust = -0.5) +
    annotate("text", x = Inf, y = astMin, label = "AST ULN",
             fontface = "plain", family = "plain", color = "black",
             size = 2.2, hjust = 1.2, vjust = -0.5)
  
  
  # calculating all total changes for each subject
  par_chg <- tableData %>% dplyr::filter(usubjid == subject[1]) %>%
    group_by(paramcd, ady) %>% summarise(total_chg = sum(chg), .groups = "drop") %>%
    pivot_wider(id_cols=paramcd, names_from=ady, values_from = total_chg)
  
  # converting all variables to character type and converting NA's into " "
  par_chg <- sapply(par_chg, as.character)
  par_chg[is.na(par_chg)] <- " "
  par_chg <- as_tibble(par_chg)
  
  # creating a table grob, removing column names and first to columns
  t1 <- gridExtra::tableGrob(par_chg,
                             theme = ttheme_minimal(base_size = 10),
                             cols = NULL)[, -c(1, 2)]
  
  # defining width and height of the table grob
  t1$widths <- unit(rep(1, ncol(t1)), "null")
  t1$heights <- unit(rep(1, nrow(t1)), "null")
  
  # creating a ggplot object from the table
  t2 <- ggplot() +
    annotation_custom(t1) +
    # putting y axis text (paramcd values), and reversing it for the right order 
    scale_y_discrete(limits = rev(par_chg$paramcd)) +
    # table title and footnote
    labs(
      title = "Change from baseline",
      caption = "AST = Aspartate Aminotransferase (U/L). ALT = Alanine Aminotransferase (U/L). ULN = Upper Limit Normal."
    ) +
    # additional styling
    theme(
      # removing plot background
      panel.background = element_blank(),
      # styling title and the footnote
      plot.title = element_text(size = 10, family = "plain",
                                face = "plain", colour = "black"),
      plot.caption = element_text(size = 8, family = "plain", face = "plain",
                                  colour = "black", hjust = 0),
      # y axis text style
      axis.text.y = element_text(size = 11, family = "plain", colour = "black"),
      # removing ticks from y axis
      axis.ticks.y = element_blank(),
    )
  
  # printing the plot
  print(plot + t2 + plot_layout(ncol = 1, heights = c(10, 3)))
  
}))
