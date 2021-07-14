# FLY a Domain Specific Language for scientific computing on the Multi Cloud 

FLY is a parallel work-flow scripting imperative language inspired by functional languages peculiarities.
FLY uses two type of run-time environment: the local machine and/or cloud infrastructure. FLY perceives a cloud computing infrastructure as a parallel computing architecture on which it is possible to execute some parts of its execution flow in parallel.

FLY main goals are:
* ___expressiveness___, in deploying scientific large-scale computing work-flows;
* ___programming usability___, writing .fly program should be straightforward for domain experts, while the interaction with the cloud environment should be completely transparent; the users do not need to know the cloud providers APIs;
* ___scalability___ either on symmetric multiprocessing (SMP) architectures or cloud computing infrastructures supporting FaaS. 

FLY is compiled in native code (Java code) and it is able to automatically exploits the computing resources available that better fit its computation requirements. The innovative aspect of FLY is constituted by the concept of ___FLY function___. A FLY function can be seen as an independent block of code, that can be executed concurrently.

| Faas Cloud Computing Infrastructure | Supported          | Under development  | Future development |
|:-------------------------------------:|:--------------------:|:--------------------:|:--------------------:|
| Amazon AWS                          | :heavy_check_mark: |                    |                    |
| Microsoft Azure                     | :heavy_check_mark: |                    |                    |
| [LocalStack](https://localstack.cloud/)| :heavy_check_mark: |                 |                    |
| Google Function                     |                    | :heavy_check_mark: |  |
| IBM Bluemix/Apache OpenWhisk        |                    |                    | :heavy_check_mark: |

Supported Languages:

|Faas Cloud Computing Infrastructure |Python | Javascript|
|:-------------------------------------:|:--------------------:|:--------------------:|
| Amazon AWS                               | :heavy_check_mark: |:heavy_check_mark:   |
| Microsoft Azure                          | :heavy_check_mark: |:heavy_check_mark:   |
| [LocalStack](https://localstack.cloud/)  | :heavy_check_mark: |:heavy_check_mark:   |

### Requirements

- Ubuntu or OSX OS
- Java 8 (or greater)
- Apache Maven 3 (or greater)
- Amazon AWS CLI and SDK
- Python 3
- Node.js 8.10

## Fly project maven archetype

Download the [fly-project-quickstart.zip](https://github.com/spagnuolocarmine/FLY-language/releases/download/Alpha-1.5/fly-project-quickstart.zip)

Unpack the fly-project-quickstart.zip:
```
unzip fly-project-quickstart.zip
```

Go to the subfolder local-repo inside the fly-project-quickstart and install the azureclient dependency:
```
cd fly-project-quickstart/src/main/resources/archetype-resources/local-repo/

mvn install:install-file -Dfile=./azureclient-0.0.1-SNAPSHOT.jar -DgroupId=isislab -DartifactId=azureclient -Dversion=0.0.1-SNAPSHOT -Dpackaging=jar
```

Go to to the top of folder fly-project-quickstart and install the maven archetype:

```
cd fly-project-quickstart/
mvn install
mvn archetype:crawl
```

## Standalone FLY compiler

Download the [fly_standalone.zip](https://github.com/spagnuolocarmine/FLY-language/releases/download/Alpha-1.5/fly_standalone.zip):  

Unzip the :
```
unzip fly_standalone.zip
```
Compile and run a .fly program :
```
cd <path-to-compiler> 

./fly-cc <name-example>.fly
```


The Standalone compiler are tested on several platform:

| Platform / Architecture     | x86 | x86_64 |
|-----------------------------|-----|--------|
| Windows (7, 8, 10, ...)     | x   | x      |
| Ubuntu (18.04 or later)     | ✓   | ✓      |
| OSX (10.12 Sierra or later) | ✓   | ✓      |

## List of Publications:
* *Towards a Domain-Specific Language for Scientific Computing on Multicloud Systems*, 1st International Workshop on Parallel Programming Models in High- Performance Cloud (ParaMo 2019).
*  *FLY: A Domain-Specific Language for Scientific Computing on FaaS*, Lect. Notes Comput. Sci. (including Subser. Lect. Notes Artif. Intell. Lect. Notes Bioinformatics), 2020.
