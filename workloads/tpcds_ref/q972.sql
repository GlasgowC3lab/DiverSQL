select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 669 and 669+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'light') and 
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'thistle') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'moccasin') and
        (i_units = 'Ton' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'burlywood') and
        (i_units = 'N/A' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'chocolate') and 
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'goldenrod') and
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'yellow') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'chiffon') and
        (i_units = 'Tbl' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100
