source("coverage_bias.R")

## HEATMAP PLOT
heatmap_plot = function(coverage_bias){
  
  ordered_coverage_bias = coverage_bias %>% select(entity, entity_type) %>% 
    distinct() %>% arrange(entity_type, entity) %>% 
    mutate(color = if_else(entity_type == "party", "red", "blue"))
  
  coverage_bias$entity <- factor(coverage_bias$entity, levels = ordered_coverage_bias$entity)
  
  hm <- ggplot(data = coverage_bias, aes(x = subFonte, y = entity, fill = cb)) + geom_tile() + 
    scale_fill_distiller(name = "Coverage", palette = "Reds", direction = 1, na.value = "transparent") +
    theme_bw() +
    theme(legend.position = "bottom", legend.direction = "horizontal",
          text = element_text(size = 15),
          axis.text.y = element_text(colour = ordered_coverage_bias$color),
          axis.text.x = element_text(angle = 15, hjust = 1)) +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5)) + 
    labs(x = "", y = "", title = coverage_bias$year %>% unique())
  return(hm)
}

p1 <- heatmap_plot(coverage_bias_2010)
p2 <- heatmap_plot(coverage_bias_2014)
p3 <- heatmap_plot(coverage_bias_2018)

p = ggarrange(p1, p2, p3, ncol=2, nrow=2, common.legend = TRUE, legend="bottom")
p
#ggsave("coverage_bias_heatmap.pdf", plot = p, device = "pdf", width = 6, height = 6)

## DOTPLOT PLOT
distributed_dot_plot = function(coverage_bias){
  ordered_coverage_bias = coverage_bias %>% select(entity, entity_type) %>% 
    distinct() %>% arrange(entity_type, entity)
  
  coverage_bias$entity <- factor(coverage_bias$entity, levels = ordered_coverage_bias$entity)
  
  ddp = ggplot(coverage_bias, aes(entity, cb)) + 
    geom_point(aes(color = subFonte), size = 3) + #, shape = coverage_bias$entity_type 
    theme_bw() + 
    facet_wrap(. ~ year, scales = "free_x", ncol = 1)+
    theme(
      text = element_text(size = 12),
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 10),
      legend.position="bottom") +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5)) + 
    labs(x = "", 
         y = "", 
         #title = coverage_bias$year %>% unique(),
         shape = "Type",
         color = "Portais") +
    ylim(-1.5, 1.5)
  
  return(ddp)
}


party = distributed_dot_plot(coverage_bias %>% filter(entity_type == "party"))
candidate = distributed_dot_plot(coverage_bias %>% filter(entity_type == "candidate"))
p = ggarrange(party, candidate, ncol=2, nrow=1, common.legend = TRUE, legend="bottom")
ggsave("coverage_bias_dot_plot_wide_2.pdf", plot = p, device = "pdf", width = 6, height = 6)


candidate_2010 = distributed_dot_plot(coverage_bias %>% filter(entity_type == "candidate", year == 2010))
candidate_2018 = distributed_dot_plot(coverage_bias %>% filter(entity_type == "candidate", year == 2018))
p = ggarrange(candidate_2010, candidate_2018, ncol=2, nrow=1, common.legend = TRUE, legend="bottom")
ggsave("coverage_bias_dot_plot_candidate_2018", plot = p, device = "jpeg", width = 12, height = 6)


## Coverage by Candidate Ideology
#coverage_bias_main_left_right = bind_rows(coverage_bias_2010, coverage_bias_2014, coverage_bias_2018) 

coverage_bias_main_left_right_candidates = coverage_bias %>% 
  filter(entity_type == "candidate", !(entity %in% c("ciro", "marina"))) %>% 
  mutate(ideology = if_else(entity %in% c("dilma","haddad"), "Left-wing","Right-wing")) %>% 
  select(subFonte, cb, year, ideology, entity_type)

coverage_bias_main_left_right_party = coverage_bias %>% 
  filter(entity_type == "party", !(entity %in% c("rede", "pdt","psb","pv"))) %>% 
  mutate(ideology = if_else(entity %in% c("pt"), "Left-wing","Right-wing")) %>% 
  select(subFonte, cb, year, ideology, entity_type, entity)


### Line Plot
ideology_plot_candidates = ggplot(data=coverage_bias_main_left_right_candidates,
                                  aes(x=as.numeric(year), y=cb)) +
  geom_point(aes(shape=ideology), size = 3) + geom_line(aes(linetype=ideology)) +
  theme_bw() + 
  facet_wrap(. ~ subFonte, nrow = 3, ncol = 2) +
  theme(
    text = element_text(size = 12),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 10),
    legend.direction = "horizontal", 
    legend.position = "bottom", 
    legend.box = "vertical") +
  labs(x = "", 
       y = "", 
       shape = "Ideology",
       color = "News Outlet",
       linetype = "Ideology") + 
  scale_x_continuous(breaks = c(2010,2014,2018), labels = c("'10","'14","'18")) + 
  scale_y_continuous(breaks = c(-1,0,1), labels = c("-1","0","1")) 
  

ggsave("coverage_bias_ideology_candidates.pdf", plot = ideology_plot_candidates, device = "pdf", width = 4, height = 4)