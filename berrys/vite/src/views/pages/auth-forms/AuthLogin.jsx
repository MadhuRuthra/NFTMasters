import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';

// material-ui
import { useTheme } from '@mui/material/styles';
import Button from '@mui/material/Button';
import Checkbox from '@mui/material/Checkbox';
import FormControl from '@mui/material/FormControl';
import FormControlLabel from '@mui/material/FormControlLabel';
import Grid from '@mui/material/Grid';
import IconButton from '@mui/material/IconButton';
import InputAdornment from '@mui/material/InputAdornment';
import InputLabel from '@mui/material/InputLabel';
import OutlinedInput from '@mui/material/OutlinedInput';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import axios from "axios";

// project imports
import AnimateButton from 'ui-component/extended/AnimateButton';

// assets
import Visibility from '@mui/icons-material/Visibility';
import VisibilityOff from '@mui/icons-material/VisibilityOff';

// ===============================|| JWT - LOGIN ||=============================== //

export default function AuthLogin() {
  const theme = useTheme();
  const navigate = useNavigate(); // ✅ Use navigate to change URL

  const RandomNumber = () => {
    return Math.floor(100000000000 + Math.random() * 900000000000).toString();
  };
  
  const [email, setEmail] = useState('info@codedthemes.com'); // ✅ Define email state
  const [password, setPassword] = useState('123456'); // ✅ Define password state
  const [checked, setChecked] = useState(true);
  const [showPassword, setShowPassword] = useState(false);

  const handleClickShowPassword = () => {
    setShowPassword(!showPassword);
  };

  const handleMouseDownPassword = (event) => {
    event.preventDefault();
  };

  const handleLogin =async (e) => {
    e.preventDefault();

    // ✅ Simulate authentication (Replace with API call)
    if (email === 'info@codedthemes.com' && password === '123456') {
      console.log('Login successful');

      try {
        const data = JSON.stringify({
          email,
          password,
          request_id: RandomNumber(),
        });

        const response = await axios.post("http://localhost:10055/login/", data, {
          headers: { "Content-Type": "application/json" },
        });

        console.log("Login Response:", response.data);
        if (response.data && response.data.response_status === 200) {
          console.log("Navigating to /dashboard/default"); // Debugging log
          sessionStorage.setItem("auth", "true");
          sessionStorage.setItem("user_bearer_token", response.data.user_bearer_token);
          sessionStorage.setItem("user_id", response.data.user_id);
          sessionStorage.setItem("user_email", response.data.user_email);
          sessionStorage.setItem("user_status", response.data.user_status);
          sessionStorage.setItem("api_key", response.data.api_key);
          navigate('/dashboard/default');

        }
        else {
          alert("Invalid Credentials!");
        }
      } catch (error) {
        console.error("Login error:", error);
        alert("An error occurred during login. Please try again.");
      }
      // ✅ Redirect to dashboard after successful login
      // navigate('/dashboard/default');
    } else {
      alert('Invalid email or password!');
    }
  };

  return (
    <>
      <FormControl fullWidth sx={{ ...theme.typography.customInput }}>
        <InputLabel htmlFor="outlined-adornment-email-login">Email Address / Username</InputLabel>
        <OutlinedInput
          id="outlined-adornment-email-login"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          name="email"
        />
      </FormControl>

      <FormControl fullWidth sx={{ ...theme.typography.customInput }}>
        <InputLabel htmlFor="outlined-adornment-password-login">Password</InputLabel>
        <OutlinedInput
          id="outlined-adornment-password-login"
          type={showPassword ? 'text' : 'password'}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          name="password"
          endAdornment={
            <InputAdornment position="end">
              <IconButton
                aria-label="toggle password visibility"
                onClick={handleClickShowPassword}
                onMouseDown={handleMouseDownPassword}
                edge="end"
                size="large"
              >
                {showPassword ? <Visibility /> : <VisibilityOff />}
              </IconButton>
            </InputAdornment>
          }
          label="Password"
        />
      </FormControl>

      <Grid container sx={{ alignItems: 'center', justifyContent: 'space-between' }}>
        <Grid item>
          <FormControlLabel
            control={<Checkbox checked={checked} onChange={(event) => setChecked(event.target.checked)} name="checked" color="primary" />}
            label="Keep me logged in"
          />
        </Grid>
        <Grid item>
          <Typography variant="subtitle1" component={Link} to="/forgot-password" color="secondary" sx={{ textDecoration: 'none' }}>
            Forgot Password?
          </Typography>
        </Grid>
      </Grid>
      <Box sx={{ mt: 2 }}>
        <AnimateButton>
          <Button color="secondary" fullWidth size="large" type="submit" variant="contained" onClick={handleLogin}>
            Sign In
          </Button>
        </AnimateButton>
      </Box>
    </>
  );
}
