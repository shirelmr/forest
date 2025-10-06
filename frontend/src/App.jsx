import { useRef, useState } from 'react'
// import './App.css'
import '@aws-amplify/ui-react/styles.css';
import { Button, SliderField } from "@aws-amplify/ui-react";

function App() {
  let [location, setLocation] = useState("");
  let [trees, setTrees] = useState([]);
  let [gridSize, setGridSize] = useState(20);
  let [simSpeed, setSimSpeed] = useState(1);
  let [density, setDensity] = useState(0.45);
  let [spread, setSpread] = useState(100);

  const running = useRef(null);

  let setup = () => {
    console.log("Hola");
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ dim: [gridSize, gridSize], density: density, spread: spread })
    }).then(resp => resp.json())
    .then(data => {
      console.log(data);
      setLocation(data["Location"]);
      setTrees(data["trees"]);
    });
  };

  const handleStart = () => {
    console.log("location", location);
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        setTrees(data["trees"]);
      });
    }, 500);
  };

  const handleStop = () => {
    clearInterval(running.current);
  }

  let burning = trees.filter(t => t.status == "burning").length;

  if (burning == 0)
    handleStop();

  let offset = 50; //(500 - gridSize * 12) / 2;

// const handleGridSizeSliderChange = (newValue) => {
//   setGridSize(newValue);
// };

  return (
    <>
      <div>
        <Button variation={"primary"} onClick={setup}>
          Setup
        </Button>
        <Button variation={"primary"} onClick={handleStart}>
          Start
        </Button>
        <Button variation={"primary"} onClick={handleStop}>
          Stop
        </Button>
        <SliderField
          label="Grid size"
          min={10} max={40} step={10}
          type='number'
          value={gridSize}
          onChange={setGridSize}
        />
        <SliderField
          label="Simulation speed"
          min={1} max={5} step={1}
          type='number'
          value={simSpeed}
          onChange={setSimSpeed}
        />
        <SliderField
          label="Simulation density"
          min={0} max={1} step={0.05}
          type='number'
          value={density}
          onChange={setDensity}
        />
        <SliderField
          label="Fire spread probability"
          min={0} max={100} step={1}
          type='number'
          value={spread}
          onChange={setSpread}
        />
      </div>
      <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"white"}}>
      {
        trees.map(tree => 
          <image 
            key={tree["id"]} 
            x={offset + 12*(tree["pos"][0] - 1)} 
            y={offset + 12*(tree["pos"][1] - 1)} 
            width={15} href={
              tree["status"] === "green" ? "./greentree.svg" :
              (tree["status"] === "burning" ? "./burningtree.svg" : 
                "./burnttree.svg")
            }
          />
        )
      }
      </svg>
    </>
  );
}

export default App
