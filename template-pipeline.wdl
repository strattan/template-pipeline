# ENCODE DCC template pipeline
# Maintainer: J. Seth Strattan


## top-level workflow

workflow template {
	# an array of bam files to work on
	Array[File] bams
	# the number of CPUs to use for each task
	Int ncpus = 1
	# the amount of memory to use for each task
	Int ramGB = 16
	# a string identifying the disk to use for each task
	String? disk

	scatter (i in range(length(bams))) {
		call flagstat { input:
			bam = bams[i]
			task_string = "flagstat "+(i+1)+" of "+length(bams)
		}

		call stats { input:
			bam = bams[i]
			task_string = "stats "+(i+1)+" of "+length(bams)
		}

	}

	call summarize_outputs { input:
		flagstat_outputs = flagstat.output
		stats_outputs = stat.output
	}


## individual tasks

# take one bam file and return output of samtools flagstat
task flagstat {
	File bam
	String task_string = ""
	Int ncpus
	Int ramGB
	String? disk

	command {
		python3 $(which flagstat.py) \
			${bam}
	}

	output {
		File output = glob("*_flagstat.txt")[0]
	}

	runtime {
		cpu: ncpus
		memory: "${ramGB} GB"
		disk: select_first([disk, "local-disk 100 SSD"])
	}
}

# take one bam file and return output of samtools stats
task stats {
	File bam
	String task_string = ""
	Int ncpus
	Int ramGB
	String? disk

	command {
		python3 $(which stats.py) \
			${bam}
	}

	output {
		File output = glob("*_stats.txt")[0]
	}

	runtime {
		cpu: ncpus
		memory: "${ramGB} GB"
		disk: select_first([disk, "local-disk 100 SSD"])
	}
}

# take two arrays of output files from samtools flagstat and stats
# and summarize
task summarize_outputs {
	Array[File] flagstat_outputs
	Array[File] stats_outputs

	command {
		python3 $(which summary.py) \
			--flagstats ${sep=' ' flagstat_outputs} \
			--stats ${sep=' ' stats_outputs}
	}

	output {
		File output = glob("summary.txt")[0]
	}
}
