select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 975 and 975+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'tomato') and 
        (i_units = 'Oz' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'metallic') and
        (i_units = 'Carton' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'honeydew') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'beige') and
        (i_units = 'Pound' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'red') and 
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'floral') and
        (i_units = 'Dram' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'maroon') and
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'papaya') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100
