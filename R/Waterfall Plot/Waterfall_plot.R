library(dplyr) # for data manipulation
library(ggplot2) # to create plots
library(ggh4x) # to resize the plot size
library(clinicalfd) # to use open source clinical data sets

# getting ADaM data set
data("adlbc")

# filtering data set by parameter, safety population, and visit number
MaxPchgs <- adlbc %>% dplyr::filter(paramcd == "GGT", saffl == "Y", avisitn > 0) %>%
  group_by(trta, usubjid) %>%
  # calculating percentage change and taking the maximum of each subject
  mutate(pchg = ifelse(!is.na(aval) & !is.na(base), 100*(aval-base)/base, NA),
         MaxPchg = max(pchg)) %>% dplyr::filter(!is.na(pchg), row_number() == 1) %>%
  select(trta, usubjid, MaxPchg) %>% arrange(trta, desc(MaxPchg)) %>% 
  ungroup() %>% group_by(trta) %>%
  mutate(xValues = row_number())

# keeping one of the classes of trta variable
class(MaxPchgs$trta) <- "factor"

# truncating values greater than 100
MaxPchgs <- MaxPchgs %>%
  mutate(ULOQ = ifelse(MaxPchg > 100, 105, NA), 
         MaxPchg = ifelse(MaxPchg > 100, 100, MaxPchg))

# defining our plot
ggplot(data = MaxPchgs, mapping = aes(x = xValues, y = MaxPchg, fill = trta, color = trta)) +
  # adding bars
  geom_col() +
  # adding "U" pointer above truncated values
  geom_point(data = MaxPchgs, mapping = aes(y = ULOQ),
             na.rm = TRUE, shape = "U", size = 1.3) +
  # defining custom fill colors for the bars of each group
  scale_fill_manual(values = c('blue', 'red', 'green')) +
  # defining custom border colors for the bars of each group
  scale_color_manual(values = c('darkblue', 'darkred', 'darkgreen')) +
  # dividing one plot into three plots (one for each group)
  facet_wrap(. ~ trta, nrow = 3) +
  # adding the title, footnote, and axes labels
  labs(
    title = "Waterfall Plot of Maximum Post Baseline Percentage Change in
GGT (Safety Analysis Set)",
    y = "Maximum post baseline percentage change",
    caption = "Each bar represents unique subject's maximum percentage change.
If subject's maximum percentage change was greater than 100 percent then the change was 
displayed as 100 and indicated with the letter U in plot. GGT = Gamma Glutamyl Transferase (U/L)."
  ) +
  theme(
    # applying border around the plot
    panel.border = element_rect(fill = NA, colour = "black", linewidth = 0.3),
    # setting full panel background to blank
    panel.background = element_blank(),
    # changing strip (each panel title) background
    strip.background =  element_rect(fill = NA, colour = "black", linewidth = 0.3),
    # changing the text (label) in each strip (each panel title)
    strip.text = element_text(size = 10, family = "plain", face = "bold"),
    # title size, family, face, color, horizontal justification, and margins around the text
    plot.title = element_text(size = 12, family = "plain", face="bold", colour = "black",
                              hjust = 0.5, margin = margin(.2, .2, .2, .2, "cm")),
    # footnote horizontal justification, style, size, color, and margins around the text
    plot.caption = element_text(hjust = 0, size = 8,color = "black",
                                margin = margin(.1, .1, .1, .1, "cm")),
    # removing x-axis title (label)
    axis.title.x = element_blank(),
    # setting y-axis title (label) size, family, and color
    axis.title.y = element_text(size = 10, family = "plain", colour = "black"),
    # removing x-axis tick labels
    axis.text.x = element_blank(),
    # setting y-axis tick labels size, family, and color
    axis.text.y = element_text(size = 8, family = "plain", colour = "black"),
    # removing x-axis ticks
    axis.ticks.x = element_blank(),
    # setting a width for y-axis ticks
    axis.ticks.y = element_line(linewidth = 0.3),
    # removing legend
    legend.position = "none"
  ) + 
  # setting custom height and width for the plot, to make it bigger
  force_panelsizes(total_width = unit(7, "in"), total_height = unit(8, "in"))
