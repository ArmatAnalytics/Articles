library(dplyr) # for data manipulation
library(tidyr) # to use pivot_wider for transposing
library(ggplot2) # to create plots
library(clinicalfd)# to use open source clinical data sets


data("adlbc")
data("adsl")


# Filtering only post baseline records, only subjects from SAF population, only necessary parameters
adlbc <- adlbc %>% dplyr::filter(avisitn > 0, saffl == "Y", paramcd %in% c("BILI", "ALT"))

# Number of subject is each treatment group (for titles)
N_Subjs <- adsl %>% group_by(trt01a) %>% mutate(N_sbjs = row_number()) %>%
  dplyr::filter(row_number() == n()) %>% select(N_sbjs, trt01a)

# Creating  variables which contain the values of upper (lower) limits of parameter's normal range.
# If more than one upper (lower) limit exists the minimum (maximum) limit has been taken
highs_lows <- adlbc %>% arrange(paramcd) %>% group_by(paramcd) %>% 
  mutate(highs = min(a1hi), lows = max(a1lo)) %>% dplyr::filter(row_number() == 1) %>% ungroup()

RefLineH1 <- highs_lows$highs[highs_lows$paramcd == "ALT"]
RefLineL1 <- highs_lows$lows[highs_lows$paramcd == "ALT"]
RefLineH2 <- highs_lows$highs[highs_lows$paramcd == "BILI"]
RefLineL2 <- highs_lows$lows[highs_lows$paramcd == "BILI"]

# Generating a data set with maximum result for each subject and parameter to be plotted
MaxRslts1 <- adlbc %>% dplyr::filter(!is.na(aval)) %>% group_by(paramcd, trta, usubjid) %>%
  mutate(maximum = max(aval))  %>%
  dplyr::filter(row_number() == 1) %>%
  select(maximum, trta, paramcd, usubjid)

# Adding the number of subjects to the main data set
MaxRslts2 <- merge(MaxRslts1, N_Subjs, by.x = "trta", by.y = "trt01a", all.x = TRUE) %>%
  mutate(trt_With_N = paste(trta, paste("(N=", N_sbjs, ")", sep=""))) %>%
  select(maximum, trt_With_N, paramcd, usubjid) %>% arrange(trt_With_N, usubjid)

# Generating the fundamental data for plot with the necessary structure
# keeping rows, where both BILI and ALT are not missing
DataForPlot <- MaxRslts2 %>% pivot_wider(names_from = paramcd, values_from = maximum) %>%
  dplyr::filter(!is.na(BILI), !is.na(ALT))


# defining our plot
ggplot(DataForPlot, aes(x = ALT, y = BILI, fill = trt_With_N)) +
  # adding scatter plot
  geom_point(show.legend = FALSE, size = 1.5, shape = "circle filled") +
  # defining custom fill colors for points of each group
  scale_fill_manual(values = c('red', 'blue', 'orange')) +
  # dividing into separate plots for each treatment group
  facet_wrap(. ~ trt_With_N) +
  # adding vertical and horizontal lines for upper and lower limits of analysis range
  geom_vline(xintercept = c(RefLineH1, RefLineL1), linetype = "longdash",
             linewidth = 0.3, alpha = 0.3) +
  geom_hline(yintercept = c(RefLineH2, RefLineL2), linetype = "longdash",
             linewidth = 0.3, alpha = 0.3) +
  # transforming the coordinate system
  coord_trans(x = "log", y = "log") +
  # adding the title, footnote, and axes labels
  labs(
    title = "Scatter Plot of Total Bilirubin vs. ALT (Safety Analysis Set)",
    x = "Maximum post baseline ALT",
    y = "Maximum post baseline total Bilirubin",
    caption = "Logarithmic scaling was used on both X and Y axis.\nEach data point represents a unique subject."
  ) +
  theme(
    # applying border around the plot
    panel.border = element_rect(fill = NA, colour = "black", linewidth = 0.3),
    # setting full panel background to blank
    panel.background = element_blank(),
    # removing spaces between panels
    panel.spacing = unit(0, "lines"),
    # changing strip (each panel title) background
    strip.background =  element_rect(fill = NA, colour = "black", linewidth = 0.3),
    # changing the text (label) in each strip (each panel title)
    strip.text = element_text(size = 10, family = "plain", face = "bold"),
    # title size, family, face, color, horizontal justification, and margins around the text
    plot.title = element_text(size = 12, colour = "black", family = "plain", face="bold",
                              hjust = 0.5, margin = margin(.2, .2, .2, .2, "cm")),
    # footnote horizontal justification, style, size, color, and margins around the text
    plot.caption = element_text(size = 8, colour = "black", family = "plain", face = "italic",
                                hjust = 0, margin = margin(.1, .1, .1, .1, "cm")),
    # increasing the space from right and left sides
    plot.margin = margin(0, .3, 0, .2, "cm"),
    # axes' labels size, family, and color
    axis.title = element_text(size = 10, family = "plain", colour = "black"),
    # axes' tick labels size, family, and color
    axis.text = element_text(size = 8, family = "plain", colour = "black"),
    # giving width to ticks 
    axis.ticks = element_line(linewidth=0.3)
  )
