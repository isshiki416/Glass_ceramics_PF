[GlobalParams]
  displacements = 'disp_x disp_y'
[]


[Mesh]
  type = FileMesh
  file = crack_mesh.msh
#   uniform_refine = 4
[]


[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./d]
  [../]
  [./phi]
  [../]
[]


[Functions]
  [./MyICFunction]
    type = ParsedFunction
    expression = 'if((x-4.450)^2 + (y-3.500)^2 < 0.300^2, 1, if((x-4.775)^2 + (y-4.500)^2 < 0.300^2, 1, if((x-1.875)^2 + (y-3.000)^2 < 0.300^2, 1, if((x-4.600)^2 + (y-2.400)^2 < 0.300^2, 1, if((x-2.675)^2 + (y-0.875)^2 < 0.300^2, 1, if((x-2.050)^2 + (y-0.150)^2 < 0.300^2, 1, if((x-4.075)^2 + (y-0.850)^2 < 0.300^2, 1, if((x-3.650)^2 + (y-3.550)^2 < 0.300^2, 1, if((x-0.250)^2 + (y-3.325)^2 < 0.300^2, 1, if((x-3.200)^2 + (y-3.100)^2 < 0.300^2, 1, if((x-0.625)^2 + (y-2.625)^2 < 0.300^2, 1, if((x-3.550)^2 + (y-2.100)^2 < 0.300^2, 1, if((x-4.525)^2 + (y-1.725)^2 < 0.300^2, 1, if((x-3.625)^2 + (y-0.250)^2 < 0.300^2, 1, if((x-1.950)^2 + (y-0.900)^2 < 0.300^2, 1, if((x-1.350)^2 + (y-4.400)^2 < 0.300^2, 1, if((x-0.475)^2 + (y-0.475)^2 < 0.300^2, 1, if((x-3.275)^2 + (y-1.250)^2 < 0.300^2, 1, if((x-0.550)^2 + (y-4.675)^2 < 0.300^2, 1, if((x-1.925)^2 + (y-3.775)^2 < 0.300^2, 1, if((x-0.400)^2 + (y-4.050)^2 < 0.300^2, 1, if((x-2.200)^2 + (y-2.425)^2 < 0.300^2, 1, if((x-1.200)^2 + (y-0.350)^2 < 0.300^2, 1, if((x-2.300)^2 + (y-4.550)^2 < 0.300^2, 1, if((x-1.725)^2 + (y-1.750)^2 < 0.300^2, 1, if((x-1.075)^2 + (y-0.975)^2 < 0.300^2, 1, if((x-4.175)^2 + (y-2.950)^2 < 0.300^2, 1, if((x-4.075)^2 + (y-4.850)^2 < 0.300^2, 1, 0))))))))))))))))))))))))))))'
  [../]
[]


[ICs]
  [./phi_IC]
    type = FunctionIC
    variable = phi
    function = MyICFunction
  [../]
[]


[AuxVariables]
  [./stress_yy]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]


[Modules]
  [./TensorMechanics]
    [./Master]
      [./All]
        add_variables = true
        strain = SMALL
        additional_generate_output = 'strain_yy strain_xy stress_yy stress_xx stress_xy'
        planar_formulation = PLANE_STRAIN
      [../]
    [../]
  [../]
[]


[Kernels]
  [./pfbulk]
    type = AllenCahn
    variable = d
    mob_name = L_d
    f_name = F_d
  [../]
  [./solid_x]
    type = PhaseFieldFractureMechanicsOffDiag
    variable = disp_x
    component = 0
    c = d
  [../]
  [./solid_y]
    type = PhaseFieldFractureMechanicsOffDiag
    variable = disp_y
    component = 1
    c = d
  [../]
  [./dcdt]
    type = TimeDerivative
    variable = d
  [../]
  [./acint]
    type = ACInterface
    variable = d
    mob_name = L_d
    kappa_name = kappa_d
  [../]
  [./dphi_dt]
    type = TimeDerivative
    variable = phi
  [../]
[]


[AuxKernels]
  [./stress_yy]
    type = RankTwoAux
    variable = stress_yy
    rank_two_tensor = stress
    index_j = 1
    index_i = 1
    execute_on = timestep_end
  [../]
[]


[BCs]
  [./ydisp_top]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = 'top'
    function = '2*t'
  [../]
  [./ydisp_bottom]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = 'bottom'
    function = '-2*t'
  [../]
  [./xfix_left]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  [../]
  [./xfix_right]
    type = DirichletBC
    variable = disp_x
    boundary = 'right'
    value = 0
  [../]
[]


[Materials]
  [./damage_stress]
    type = ComputeLinearElasticPFFractureStress
    c = d
    E_name = 'elastic_energy'
    D_name = 'degradation'
    F_name = 'local_fracture_energy'
    decomposition_type = stress_spectral
    use_current_history_variable = true
  [../]
  [./degradation]
    type = DerivativeParsedMaterial
    property_name = degradation
    coupled_variables = 'd'
    expression = '(1.0-d)^2*(1.0 - eta) + eta'
    constant_names       = 'eta'
    constant_expressions = '1.0e-6'
    derivative_order = 2
  [../]
  [./local_fracture_energy]
    type = DerivativeParsedMaterial
    property_name = local_fracture_energy
    coupled_variables = 'd'
    material_property_names = 'gc_prop l'
    expression = 'd^2 * gc_prop / 2 / l'
    derivative_order = 2
  [../]
  [./fracture_driving_energy]
    type = DerivativeSumMaterial
    args = d
    sum_materials = 'elastic_energy local_fracture_energy'
    derivative_order = 2
    property_name = F_d
  [../]
  [./pfbulkmat1] # rho in 1e3 kg/um3 gc in GPa um for material
    type = GenericConstantMaterial
    prop_names = 'gc_glass gc_crys'
    prop_values = '1e-3 1.969e-3'
  [../]
  [./pfbulkmat2] # rho in 1e3 kg/um3 gc in GPa um for model
    type = GenericConstantMaterial
    prop_names = 'l L_d'
    prop_values = '5e-3 1e6'
  [../]
  [./kappa_d]
    type = ParsedMaterial
    property_name = kappa_d
    material_property_names = 'gc_prop l'
    expression = 'gc_prop*l'
  [../]
  [./gc_prop]
    type = DerivativeParsedMaterial
    property_name = gc_prop
    coupled_variables = 'phi'
    material_property_names = 'gc_glass gc_crys'
    expression = 'gc_glass+(gc_crys-gc_glass)*phi'
    derivative_order = 2
  [../]
  [./elasticity_tensor]
    type = ComputeConcentrationDependentElasticityTensor
    c = phi
    C1_ijkl = '292.9 113.9 0 292.9 0 0 0 0 89.5'
    C0_ijkl = '105.3 33.2 0 105.3 0 0 0 0 36'
    fill_method1 = symmetric9
    fill_method0 = symmetric9
  [../]
[]


[Preconditioning]
  active = 'smp'
  [./smp]
    type = SMP
    full = true
  [../]
[]


[Postprocessors]
  [./disp_y_top]
    type = SideAverageValue
    variable = disp_y
    boundary = 'top'
  [../]
  [./stressyy]
    type = ElementAverageValue
    variable = stress_yy
  [../]
[]


[Executioner]
  type = Transient
  solve_type = PJFNK
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu superlu_dist'

  nl_rel_tol = 1e-8
  l_max_its = 50
  nl_max_its = 100

  dt = 5e-6
  dtmin = 1e-15
  start_time = 0.0
  end_time = 0.0075
  
  [./Adaptivity]
    initial_adaptivity = 4
    max_h_level = 4
    refine_fraction = 0.95
    coarsen_fraction = 0.05
  [../]
[]


[Outputs]
  file_base = ModeIstressspectr
  interval = 10
  exodus = true
  csv = true
  gnuplot = true
[]
