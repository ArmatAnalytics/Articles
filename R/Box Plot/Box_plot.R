library(dplyr) # for data manipulation
library(ggplot2) # to create plots
library(clinicalfd) # to use open source clinical data sets


data("adlbc")
adlbc <- adlbc %>% filter(paramcd == "SODIUM", !is.na(avisitn), saffl == "Y")

ggplot(aes(x = as.factor(avisitn), y = aval, color = trta, fill = trta)) +
  # adding error bars to box plot, for min and max horizontal lines
  # position dodge is used to put the bars of each treatment on its' box plot
  stat_boxplot(geom = "errorbar", position = position_dodge(width = .75), width = 0.5) +
  # geom_boxplot with position_dodge2 to add space between box plots for each visit
  geom_boxplot(outlier.shape = 1, position = position_dodge2(padding = 0.3)) +
  # using stat_summary for mean points
  # function is mean, geometric object is point
  # position dodge is used to put the mean of each treatment on its' box plot
  stat_summary(fun = mean, geom = "point", shape = 1, size = 3.5, position = position_dodge(width = .75)) +
  # fill and border colors are given manually 
  scale_fill_manual(values = c("steelblue", "khaki", "lightgreen")) +
  scale_color_manual(values = c("midnightblue", "saddlebrown", "darkgreen")) +
  labs(
    title = "Test Results for Sodium in Each Visit", # plot title
    x = "Visit", # x axis title
    y = "Sodium (mmol/L)", # y axis title
    # giving the same name to color and fill legends, not to separate them
    color = "Treatment Groups: ",
    fill = "Treatment Groups: ",
  ) +
  theme(
    # applying border around the plot
    panel.border = element_rect(fill = NA, colour="black", linewidth = 0.3),
    # setting full panel background to blank
    panel.background = element_blank(),
    # title size, family, face, color, horizontal justification, and margins around the text
    plot.title = element_text(size = 12, family = "plain", face="bold", colour = "black",
                              hjust = 0.5, margin = margin(.2, .2, .2, .2, "cm")),
    # axes' labels size, family, and color
    axis.title = element_text(size = 10, family = "plain", colour = "black"),
    # axes' tick labels size, family, and color
    axis.text = element_text(size = 8, family = "plain", colour = "black"),
    # giving width to ticks 
    axis.ticks = element_line(linewidth = 0.3),
    # removing legend elements' background
    legend.key = element_blank(),
    # setting legend title size
    legend.title = element_text(size = 10),
    # setting legend text size
    legend.text = element_text(size = 10),
    # giving rectangle border to the legend
    legend.background = element_rect(colour = "black", linewidth = 0.2),
    # setting legend position
    legend.position = "bottom"
  )