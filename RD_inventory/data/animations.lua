return {
    eat = { dict='mp_player_inteat@burger', clip='mp_player_int_eat_burger', prop={ model=`prop_cs_burger_01`, pos=vec3(0.02,0.02,-0.02), rot=vec3(0.0,0.0,0.0) }, usetime=2500, disable={ move=false, car=true, combat=true } },
    eating = { dict='mp_player_inteat@burger', clip='mp_player_int_eat_burger', prop='burger', usetime=2500 },
    drink = { dict='mp_player_intdrink', clip='loop_bottle', prop={ model=`prop_ld_flow_bottle`, pos=vec3(0.03,0.03,0.02), rot=vec3(0.0,0.0,-1.5) }, usetime=2500, disable={ car=true, combat=true } },
    radio = { dict='random@arrests', clip='generic_radio_chatter', usetime=1000 },
    bandage = { dict='missheistdockssetup1clipboard@idle_a', clip='idle_a', prop={ model=`prop_rolled_sock_02`, pos=vec3(-0.14,-0.14,-0.08), rot=vec3(-50.0,-50.0,0.0) }, usetime=2500, disable={ move=true, car=true, combat=true } },
    armour = { dict='clothingshirt', clip='try_shirt_positive_d', usetime=3500 },
    clothing = { dict='clothingshirt', clip='try_shirt_positive_d', usetime=1500 }
}
