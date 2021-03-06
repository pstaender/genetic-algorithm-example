SolvingCombinationWithGeneticAlgorithm = window.SolvingCombinationWithGeneticAlgorithm
Chromosome = window.Chromosome

$(document).ready ->

  # eval is evil, but here it's just a workaround for cson parsing

  data = window.CoffeeScript.eval($('pre#data').text())

  options = {}

  $('[contenteditable]').each ->
    $this = $(this)
    options[$this.attr('id')] = $this.text()

  $('body')
    .on 'focus', '[contenteditable]', ->
      $this = $(this)
      $this.data 'before', $this.html()
      return $this
    .on 'blur keyup paste input', '[contenteditable]', ->
      $this = $(this)
      if $this.data('before') isnt $this.html()
        $this.data 'before', $this.html()
        $this.trigger('change')
        options[$this.attr('id')] = $this.text()
      return $this

  $results = $('#results')
  $button = $('button#go')
  $button.restoreText = -> @text(@data('text'))
  $button.restoreText()
    

  $button.on 'click', ->

    $button.removeClass('blinking')

    $button.text('iterating …')

    setTimeout ->

      $results.html('')

      maxIterations = Number(options.maxIterations)

      Chromosome::toHTML = ->
        $html = $("""
        <div class="chromosome">
          <span class="a">#{@code[0]}</span>
          <span class="b">#{@code[1]}</span>
          <span class="c">#{@code[2]}</span>
          <span class="d">#{@code[3]}</span>
          <span class="totalRevenue">#{@totalRevenue()}$</span>
          <span class="requestedChairs">#{@evaluateRequestedChairs()} ⑁</span>
          <span class="fitness">#{ga.round(@fitness())}</span>
        </div>
        """)

      log = (description = "", data = "") ->
        if data
          console.log(description, data)
        else
          console.log(description)

      SolvingCombinationWithGeneticAlgorithm::crossoverRate = Number(options.crossoverRate)
      SolvingCombinationWithGeneticAlgorithm::mutationRate = Number(options.mutationRate)
      Chromosome::valueSet = data
      # for valuesetKey in [ 'a', 'b', 'c', 'd' ]
      #   if options['valueset_'+valuesetKey]
      #     valueset = options['valueset_'+valuesetKey]

      #     if /(,\s*)*(…|\.\.\.)(,\s*)*/.test(valueset)
      #       parts = valueset.trim().match(/^([0-9]+).*\s*(,\s*)*(…|\.\.\.)(,\s*)*.*?([0-9]+)$/)
      #       numbers = for i in [ Number(parts[1]) .. Number(parts[5])]
      #         i
      #       # console.error parts
      #       # Chromosome::minValue = Number(parts[1])
      #       # Chromosome::maxValue = Number(parts[5])
      #     else
      #       numbers = for number in valueset.split(',')
      #         Number(number)
      #     Chromosome::valueSet.push(numbers)

      SolvingCombinationWithGeneticAlgorithm::numberOfChromosomes = 6
      Chromosome::chairCapacity = Number(options.add_1)
      Chromosome::factors =
        a: Number(options.factor_1)
        b: Number(options.factor_2)
        c: Number(options.factor_3)
        d: Number(options.factor_4)

      console.error Chromosome::factors

      ga = new SolvingCombinationWithGeneticAlgorithm()
      ga.initPopulation()

      log """
        \nInitialization

        General objective function:
        f(x) = #{ga.population[0].asObjectiveFunction(false)}

        Generating #{ga.numberOfChromosomes} random chromosomes initially
      """

      solutionFound = false

      bestChromosome = null

      for iterationStep in [1..maxIterations]

        $populationHTML = $("""
        <div class="population">
          <div class="number">#{iterationStep}</div>
        <div>
        """)

        log "\n=> ITERATION ##{iterationStep}\n"

        log "[#{i}]:\t#{chromosome.toString()}" for chromosome, i in ga.population

        log """
          \nEvaluate\n
        """
        for chromosome, i in ga.population
          # check fitness value for each chromosome
          
          log "[#{i}]:\tfitnessValue = \t#{ga.round(chromosome.fitness())}" 

          $chromosome = $(chromosome.toHTML())
          $populationHTML.append($chromosome)
          $results.append($populationHTML)
          chromosome.$chromosome = $chromosome
          
          if not bestChromosome
            bestChromosome = chromosome
          else if chromosome.fitness() > bestChromosome.fitness()
            bestChromosome = chromosome


          isOptimalSolution = chromosome.hasOptimalSolution()

          if chromosome.hasOptimalSolution()

            chromosome.$chromosome.addClass('best')
            log "\n===>\tFound #{(isOptimalSolution) ? 'optimal' : ''} solution with #{chromosome.toString()}:"
            log "fitnessValue = #{chromosome.fitness()}"
            log "Iterations: #{iterationStep}"
            solutionFound = chromosome
            # stop here

          
        # stop here, if solution is found bevore max iterations reached
        break if solutionFound

        log """
          \nSelection
          Fitness for chromosomes\n
        """

        # fitnesses = ga.fitness()
        log "[#{i}]:\t#{ga.round(chromosome.fitness())} (fitness)" for chromosome, i in ga.population

        totalFitness = ga.totalFitness()
        log """
          Sum of fitness:
          #{ga.round(totalFitness)}
        """
        probabilities = for chromosome in ga.population
          chromosome.probability(totalFitness)

        log "Probabilities:"
        log "[#{i}]:\t#{ga.round(prob)}" for prob, i in probabilities

        log "Cumulative Probability:"
        log "[#{i}]:\t#{ga.round(prob)}" for prob, i in ga.cumulativeProbability()
        #log "∑ = ", ga.cumulativeProbability().reduce (prev, curr, i, array) -> prev + curr

        randomNumbers = ga.randomNumbers()

        log "Random Numbers between 0 and 1:"
        log "[#{i}]:\t#{ga.round(rand)}" for rand, i in randomNumbers

        log "Selecting next generation by roulette-wheel"
        nextGeneration = ga.selectNextGenerationByRouletteWheel(randomNumbers)
        log "[#{i}]:\t#{chromosome.toString()}" for chromosome, i in nextGeneration

        ga.population = nextGeneration

        
        log "Selecting parents, crossoverRate = #{ga.crossoverRate}"
        pairs = ga.selectPairsByCrossoverRate(ga.crossoverRate)
        parents = ga.parents
        log "[#{i}]:\t#{chromosome.toString()}" for chromosome, i in parents
        log "Mixing Pairs"
        log "#{pair[0]?.toString()}\t↔   #{pair[1]?.toString()}" for pair, i in pairs
        log "Singlepoint Crossover"

        children = []

        for pair, i in pairs
          k = new Chromosome().randomCrossoverPoint() # just generate a random k
          child1 = pair[0].createDescendantBySingleCrossoverPoint(pair[1], k)
          child1.pos = pair[0].pos
          log "[#{i}]\tk=#{child1.crossoverPoint}\t→   #{child1.toString('┇',child1.crossoverPoint)}"
          children.push(child1)

          child2 = pair[1].createDescendantBySingleCrossoverPoint(pair[0], k)
          child2.pos = pair[1].pos
          log "[#{i}]\tk=#{child2.crossoverPoint}\t→   #{child2.toString('┇',child2.crossoverPoint)}"
          children.push(child2)

        ga.assignChildrenToPopulation(children)

        log "Result"
        log "[#{i}]:\t#{chromosome.toString()}" for chromosome, i in ga.population

        log "Mutate, mutationRate = #{ga.mutationRate}"
        ga.mutatePopulation()

        for chromosome, i in ga.population
          if chromosome.mutationPoint
            c = chromosome.clone()
            c.code[c.mutationPoint] = "[#{c.code[c.mutationPoint]}]"
            log "[#{i}]:\t#{c.toString()} ←"
          else
            log "[#{i}]:\t#{chromosome.toString()}" 

      if bestChromosome.hasOptimalSolution()
        $button.text("Optimal solution Found: #{solutionFound.toString()}")
        $button.addClass('blinking')
      else
        $button.text("Best solution found: #{bestChromosome.toString()}")
        bestChromosome.$chromosome.addClass('best')
        id = "chromosome#{bestChromosome.toStringVerbose().replace(/\s+/g,'')}"
        bestChromosome.$chromosome.attr('id', id)
        setTimeout ->
          document.location.hash = "##{id}"
        , 100
        console.error bestChromosome.$chromosome[0]
      

      buttonText = $button.text() # restore button text

      $('.population .chromosome').on 'click', ->
        $(@).toggleClass('expanded')
    , 100